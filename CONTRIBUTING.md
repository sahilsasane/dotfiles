# Contributing

Thanks for taking the time to improve these dotfiles.

This is a personal, macOS-focused setup, so a change should preserve the
existing workflow and remain useful across machines. For larger behavior
changes, open an issue first so the approach can be agreed on before work
starts.

## Make a change

1. Fork the repository and create a focused branch.
2. Keep machine-specific paths, credentials, tokens, caches, and application
   state out of commits.
3. Match the structure and style of the surrounding configuration.
4. Update `README.md` when installation steps, linked files, dependencies, or
   user-facing behavior change.
5. Open a pull request describing the reason for the change and how it was
   tested.

## Validate

Run the checks relevant to the files you changed:

```sh
# Bash scripts
bash -n bin/* tmux/scripts/*.sh

# Zsh configuration
zsh -n zsh/.zprofile zsh/.zshrc zsh/profile.d/*.zsh zsh/rc.d/*.zsh

# Whitespace errors
git diff --check
```

Also exercise the affected command or application manually. Do not run
`bin/bootstrap` or `bin/install.sh` just to validate unrelated documentation or
configuration changes because they modify the local machine.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
For vulnerabilities or accidentally committed secrets, follow the
[Security Policy](.github/SECURITY.md) instead of opening a public issue.
