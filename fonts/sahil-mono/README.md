# Sahil Mono

JetBrains Mono with the Ghostty character variants carried in the default `calt`
feature, for applications such as Rex that do not expose OpenType feature tags.
Keep **Ligatures enabled** in Rex. Existing operator ligatures are preserved.

Features: `ss02 cv03 cv04 cv08 cv14 cv15 cv16 cv18 cv19 cv20 zero`, plus `calt`.
All 16 static faces have distinct Sahil Mono family and PostScript names; original
fonts can remain installed. Nerd Font icons use Rex's existing fallback fonts.

Source: [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), commit
`19371302b95d218af43299bce79ddbddd0bc364d`. The original OFL license and font
credits are preserved. `manifest.json` records source/output hashes and checks.

Build in a temporary folder with Python 3:

```sh
git clone https://github.com/JetBrains/JetBrainsMono.git /tmp/sahil-mono-source
git -C /tmp/sahil-mono-source checkout 19371302b95d218af43299bce79ddbddd0bc364d
python3 -m venv /tmp/sahil-mono-venv
/tmp/sahil-mono-venv/bin/pip install fonttools==4.68.0 uharfbuzz==0.57.0
/tmp/sahil-mono-venv/bin/python fonts/sahil-mono/build.py \
  --source-root /tmp/sahil-mono-source --output /tmp/sahil-mono-dist
```

The builder fails on missing features or shaping differences. The initial build
passed 1,000,992 HarfBuzz comparisons across all faces and six language settings,
checking glyphs, clusters, advances, and offsets. A separate macOS CoreText check
passed 144,576 comparisons across all faces, including every printable ASCII
pair and representative ligature/variant strings.

Install the generated `SahilMono-*.ttf` files in `~/Library/Fonts`, then select
**Sahil Mono** in Rex Settings → Terminal → Choose. Select **Light**, **17 pt**
to retain the settings in use when this font was installed. Reverting only
requires selecting the previous JetBrains font; no original font is replaced.
