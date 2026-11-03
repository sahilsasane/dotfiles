# Rex copy-mode latency benchmark

Measured on 2 November 2026 using Rex `0.0.1793377904-ge6592f` on this Mac
(8 logical CPUs). The direct-launch overlay is the active configuration.
The first comparison records the initial optimization.

| Scrollback | Before median (range) | After median (range) | Reduction |
| --- | --- | --- | --- |
| 100 lines, 6,619 captured bytes | 815 ms (793–899) | 146 ms (124–154) | 82.1% |
| 10,000 lines, 660,019 captured bytes | 842 ms (784–884) | 150 ms (147–185) | 82.2% |

Each row uses seven runs per side, alternating before/after. All 28 trials
passed. Each opens a fresh terminal and Neovim process, with warm OS caches and
an existing Rex server. Every terminal was 80×24. The Neovim configuration is
identical on both sides.

The timer starts immediately before CLI dispatch of the `copy_mode` action and
ends when a capture of the new terminal contains the fixture's final marker,
the copy-mode status line, and the correct total line count. It includes
terminal creation, shell startup, capture, Neovim startup, and observing the
rendered frame. It does **not** measure physical keyboard input or native app
paint/animation. Capture polling adds an observation delay; the harness sleeps
5 ms between requests, and each request also takes time.

After the timed region, each trial dismisses the overlay and checks that it was
removed and focus returned to the source. Incorrect content, startup failures,
cleanup failures, timeouts, and changes in terminal dimensions fail the run.
The final comparison recorded zero failures. System background load was
present: the one-minute load average went from 4.90 to 4.50. Alternation gives
both sides exposure to that load, and their timing ranges do not overlap.

Separate instrumented diagnostics, excluded from the statistics above, locate
the main delay. For the 100-line fixture, dispatch plus shell startup took
784 ms before and 61 ms after. Capture took 25/30 ms and Neovim startup plus
initial redraw took 35/36 ms. The change skips login-shell runtime setup,
launches `/bin/sh` directly, and puts Homebrew's Neovim on the overlay's PATH.
The remaining time includes terminal creation, capture, and a fresh Neovim.

The faster startup also exposed Rex retaining a terminal dismissed within its
quick-exit threshold, even after exit code 0. The overlay now sets that
threshold to zero so a rapid `q` removes it normally.

After adding Extrakto and loading Flash only when `s` is pressed, a separate
comparison against the same frozen original verified the current configuration:

| Scrollback | Before median (range) | Current median (range) | Reduction |
| --- | --- | --- | --- |
| 100 lines | 910 ms (847 to 959) | 159 ms (145 to 167) | 82.6% |
| 10,000 lines | 910 ms (876 to 999) | 161 ms (153 to 165) | 82.3% |

This run used the same fixtures, dimensions, and seven alternating trials per
side. All 28 trials passed. Functional tests ran separately. The one-minute
load average went from 3.33 to 3.90. Separate stage diagnostics measured about
65 to 70 ms for dispatch and shell startup, 32 to 42 ms for capture, and
41 to 51 ms for Neovim startup and redraw. Native app paint remains outside
the timer. The [current raw results](with-features.json) include configuration
hashes, all samples, stage diagnostics, and zero recorded errors.

- [Frozen original configuration](before/init.lua) and [original viewer](before/copy-mode.lua)
- [Initial baseline runs](baseline.json)
- [Raw alternating runs, hashes, stage diagnostics, and errors](results.json)
- [Benchmark harness](benchmark.py)

Rerun from the repository root against the frozen original and current config:

```sh
python3 benchmarks/rex-copy-mode/benchmark.py --profile --runs 7 --lines 100 10000 --output benchmarks/rex-copy-mode/with-features.json
```

The harness uses disposable Rex sessions and deletes only the sessions it
creates. It does not write to the clipboard. Separate functional checks cover
selection/yanking, snapshot cleanup, pane bounds, and focus/zoom restoration.
