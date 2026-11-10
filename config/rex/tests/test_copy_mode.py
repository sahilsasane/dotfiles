"""Run with: python3 -m unittest discover -s config/rex/tests -p test_copy_mode.py"""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import secrets
import shutil
import signal
import struct
import tempfile
import termios
import time
import unittest


VIEWER = Path(__file__).resolve().parents[1] / 'copy-mode-view.lua'
NVIM = shutil.which('nvim')


@unittest.skipUnless(NVIM, 'Neovim is required')
class CopyModeTests(unittest.TestCase):
    def check_layout(self, columns, rows, history, cursor_row, cursor_column):
        with tempfile.TemporaryDirectory(prefix='rex-copy-test-') as work:
            work = Path(work)
            snapshot = work / ('rex-copy-mode-' + secrets.token_hex(4))
            snapshot.mkdir(mode=0o700)
            lines = [f'history {index}' for index in range(history)]
            right = 'postgres · 1'
            lines += ['prompt' + ' ' * (columns - 6 - len(right)) + right,
                      'Åäö 日本語 🎉\timage', 'x' * columns] + [''] * (rows - 3)
            (snapshot / 'meta.json').write_text(json.dumps({
                'title': 'Copy fixture', 'source_size': {'columns': columns, 'rows': rows}}))
            (snapshot / 'capture.vt').write_bytes(
                ('\r\n'.join(lines) + f'\033[{cursor_row};{cursor_column}H').encode())
            report = work / 'observed.json'
            observer = work / 'observe.lua'
            observer.write_text('''local function observe()
  vim.defer_fn(function()
    local result = {
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
      cursor_row = vim.api.nvim_win_get_cursor(0)[1],
      cursor_column = vim.fn.virtcol('.'),
      topline = vim.fn.winsaveview().topline,
    }
    vim.fn.writefile({ vim.json.encode(result) }, ''' + json.dumps(str(report)) + ''')
    vim.cmd('qa!')
  end, 150)
end
if #vim.api.nvim_list_uis() == 0 then
  vim.api.nvim_create_autocmd('UIEnter', { once = true, callback = observe })
else observe() end
''')
            pid, terminal = pty.fork()
            if pid == 0:
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', rows, columns, 0, 0))
                os.environ.update(TERM='xterm-256color', NVIM_LOG_FILE=str(work / 'nvim.log'))
                os.execv(NVIM, [NVIM, '-u', 'NONE', '-i', 'NONE', '-n',
                               '--cmd', 'lua vim.g.rex_copy_mode_directory = ' + json.dumps(str(snapshot)),
                               '-c', 'lua dofile(' + json.dumps(str(VIEWER)) + ')',
                               '-c', 'lua dofile(' + json.dumps(str(observer)) + ')'])
            exited = False
            output = b''
            try:
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if select.select([terminal], [], [], .02)[0]:
                        try:
                            output = (output + os.read(terminal, 65536))[-4000:]
                        except OSError:
                            pass
                    child, status = os.waitpid(pid, os.WNOHANG)
                    if child:
                        exited = True
                        self.assertEqual(os.waitstatus_to_exitcode(status), 0, 'viewer failed to start')
                        break
                self.assertTrue(exited, 'viewer did not finish the fixture: ' + repr(output))
                self.assertTrue(report.exists(), 'viewer did not render the fixture')
                actual = json.loads(report.read_text())
                self.assertEqual(actual['lines'], [line.replace('\t', '   ') for line in lines])
                self.assertEqual(actual['cursor_row'], history + cursor_row)
                self.assertEqual(actual['cursor_column'], cursor_column)
                self.assertEqual(actual['topline'], history + 1)
                self.assertFalse(snapshot.exists(), 'viewer did not clean up its capture')
            finally:
                if not exited:
                    os.killpg(pid, signal.SIGKILL)
                    os.waitpid(pid, 0)
                os.close(terminal)

    def test_wide_table_and_cursor_in_empty_screen_space(self):
        self.check_layout(178, 48, 23, 8, 6)

    def test_cursor_after_unicode_and_tab_with_scrollback(self):
        self.check_layout(120, 30, 1000, 2, 20)

    def test_cursor_at_last_cell_of_full_row(self):
        self.check_layout(60, 12, 0, 3, 60)


if __name__ == '__main__':
    unittest.main()
