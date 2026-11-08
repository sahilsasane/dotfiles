import os
from pathlib import Path
import subprocess
import tempfile
import unittest


PROMPT_RC = Path(__file__).resolve().parents[1] / 'rc.d' / '90-oh-my-posh.zsh'


class DataOSPromptTests(unittest.TestCase):
    def test_namespace_refreshes_and_clears_when_unavailable(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-dataos-prompt-') as directory:
            root = Path(directory)
            for name, content in {
                'oh-my-posh': '#!/bin/sh\nprintf "set_poshcontext() { :; }\\n"\n',
                'dataos-ctl': '#!/bin/sh\nprintf "%s\\n" "$TEST_TENANTS"\nexit "${TEST_STATUS:-0}"\n',
            }.items():
                executable = root / name
                executable.write_text(content)
                executable.chmod(0o755)

            env = os.environ.copy()
            env['PATH'] = str(root)
            result = subprocess.run(
                ['/bin/zsh', '-df', '-c', '''
source "$1"
export TEST_TENANTS=$'  ai - sawaniks.instance.dataos.cloud (ai)\n* psg - productsandbox.instance.dataos.cloud (stg)\n\n⛺️...stg'
set_poshcontext
[[ "$DOTFILES_DATAOS_NAMESPACE" == stg ]] || exit 1

export TEST_TENANTS='* seng - sawaniks.instance.dataos.cloud (engineering)'
set_poshcontext
[[ "$DOTFILES_DATAOS_NAMESPACE" == engineering ]] || exit 2

source "$1"
set_poshcontext
[[ "$DOTFILES_DATAOS_NAMESPACE" == engineering ]] || exit 6

export TEST_STATUS=1
set_poshcontext
[[ -z "$DOTFILES_DATAOS_NAMESPACE" ]] || exit 3

export TEST_STATUS=0 TEST_TENANTS='  seng - sawaniks.instance.dataos.cloud (engineering)'
set_poshcontext
[[ -z "$DOTFILES_DATAOS_NAMESPACE" ]] || exit 4

export DOTFILES_DATAOS_NAMESPACE=stale
path=()
set_poshcontext
[[ -z "$DOTFILES_DATAOS_NAMESPACE" ]] || exit 5
''', 'test', str(PROMPT_RC)],
                env=env, text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            self.assertEqual(result.stdout, '')
            self.assertEqual(result.stderr, '')


if __name__ == '__main__':
    unittest.main()
