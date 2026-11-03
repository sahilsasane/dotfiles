import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


RC_DIR = Path(__file__).resolve().parents[1] / 'rc.d'


class VenvLifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='dotfiles-venv-')
        cls.root = Path(cls.temp.name).resolve()
        cls.venv = cls.root / 'project [one]' / '.venv'
        cls.other = cls.root / 'other' / '.venv'
        for path in (cls.venv, cls.other):
            subprocess.run([sys.executable, '-m', 'venv', '--without-pip', '--prompt', 'project-name', str(path)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def shell(self, body, inherited=False, stale=False):
        env = os.environ.copy()
        for key in ('VIRTUAL_ENV', 'VIRTUAL_ENV_PROMPT', '_OLD_VIRTUAL_PATH', 'PYTHONHOME'):
            env.pop(key, None)
        env.update(TEST_ENV=str(self.venv), OTHER_ENV=str(self.other), VIRTUAL_ENV_DISABLE_PROMPT='1', BASE_PATH=env['PATH'])
        if inherited or stale:
            env['PATH'] = str(self.venv / 'bin') + os.pathsep + env['PATH']
        if inherited:
            env['VIRTUAL_ENV'] = str(self.venv)
        script = '''source "$1"
source "$2"
check_inactive() {
  [[ -z ${VIRTUAL_ENV:-} ]] || { print -u2 'VIRTUAL_ENV remains active'; return 1; }
  [[ "$PATH" == "$BASE_PATH" ]] || { print -u2 'PATH was not restored exactly'; return 1; }
  local executable
  for executable in "$(whence -p python)" "$(whence -p python3)"; do
    [[ "$executable" != "$TEST_ENV/bin/"* && "$executable" != "$OTHER_ENV/bin/"* ]] || {
      print -u2 "venv interpreter remains selected: $executable"
      return 1
    }
  done
}
''' + '\neval \"$3\"'
        result = subprocess.run(['zsh', '-df', '-c', script, 'test', str(RC_DIR / '40-aliases.zsh'), str(RC_DIR / '70-functions.zsh'), body], env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def test_reactivation_after_shell_reload_restores_base_interpreter(self):
        self.shell('for cycle in 1 2 3; do\n  v "$TEST_ENV" || exit\n  vd\n  check_inactive || exit 1\ndone', inherited=True)

    def test_deactivate_inherited_environment_without_bookkeeping(self):
        self.shell('vd\ncheck_inactive', inherited=True)

    def test_deactivate_stale_interpreter_without_activation_variable(self):
        self.shell('vd\ncheck_inactive', stale=True)

    def test_normal_switching_and_repeated_deactivation(self):
        self.shell('v "$TEST_ENV" || exit\nv "$OTHER_ENV" || exit\n[[ "$VIRTUAL_ENV" == "$OTHER_ENV" ]] || exit 1\nvd\nvd\ncheck_inactive')

    def test_deactivation_restores_pythonhome(self):
        self.shell('export PYTHONHOME=original-python-home\nv \"$TEST_ENV\" || exit\n[[ -z ${PYTHONHOME:-} ]] || exit 1\nvd\n[[ \"$PYTHONHOME\" == original-python-home ]] || exit 1\ncheck_inactive')

    def test_invalid_target_preserves_active_environment(self):
        self.shell('v "$TEST_ENV" || exit\nv "$TEST_ENV/missing" 2>/dev/null && exit 1\n[[ "$VIRTUAL_ENV" == "$TEST_ENV" ]] || exit 1\n[[ "$(whence -p python3)" == "$TEST_ENV/bin/python3" ]]')


if __name__ == '__main__':
    unittest.main()
