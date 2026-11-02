# Use Fn as the terminal prefix

Tap and release Fn, then press `h` to use the existing Ctrl-Space prefix in Rex or tmux. The rule applies only to Rex, Ghostty, and Kitty. Tmux uses its terminal's app identity.

1. In macOS System Settings, open **Keyboard** and set **Press Fn key to** or **Press Globe key to** to **Do Nothing**.
2. Finish Karabiner-Elements setup, including its required background services and permissions.
3. Copy `fn-prefix.json` to `~/.config/karabiner/assets/complex_modifications/fn-prefix.json`.
4. Select your intended profile in Karabiner-Elements. Add the rule **Tap Fn for Ctrl-Space in Rex, Ghostty, and Kitty** under **Complex Modifications**.
5. Tap and release Fn, then press `h` in Rex or a tmux pane. Confirm that the existing prefix action runs.

Do not replace `karabiner.json` to install this asset. To disable it, remove this rule from the selected profile's complex modifications.

The rule sends Ctrl-Space when Fn is released alone within Karabiner's default 1000 ms timeout. It adds no wait after release. Holding Fn with another key sends Fn as a lazy modifier and cancels the tap action. Caps Lock may be active. Other held modifiers, such as Command, do not match the rule.

Karabiner documents the release event and timeout in [to_if_alone](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-if-alone/). The [lazy modifier documentation](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/lazy/) explains why an Fn tap does not also forward a standalone Fn event.

Validate the asset with the installed CLI.

```sh
'/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli' \
  --lint-complex-modifications 'macos/karabiner/fn-prefix.json'
```

Physical keyboard verification remains pending. After setup, check Fn tap followed by `h`, Fn with arrow keys, Fn with function keys, Command-Fn, and Fn with Caps Lock active. Repeat the tap check in each target app and confirm that another app retains its normal Fn behavior. Confirm that a tap does not open the emoji picker.
