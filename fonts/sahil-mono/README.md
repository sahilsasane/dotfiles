# Sahil Mono

JetBrains Mono with the Ghostty character variants baked into its default glyph
outlines and carried in the default `calt` feature. This supports applications
such as Rex that do not expose OpenType feature tags and sometimes draw isolated
characters without text shaping. Keep **Ligatures enabled** in Rex for operator
ligatures.

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

The builder keeps Unicode mappings and ligature inputs unchanged. It copies the
selected variant's outline and metrics onto each affected base glyph. Private
copies preserve the original base shapes wherever other composite glyphs use
them. This avoids the operator-ligature regressions caused by remapping Unicode
characters directly to alternate glyphs.

Verification covers every original glyph's decomposed outline and metrics,
including the changed base glyphs. It also compares shaped glyph names,
clusters, positions, outlines, and metrics for Unicode characters, every
printable ASCII pair, and representative strings across all 16 faces and six
language settings. Upstream's Dutch language system exposes only `locl`, so
Dutch intentionally gains the baked default shapes while retaining upstream
glyph selection, positioning, and localized substitutions. The verifier checks
that this exception still matches the upstream language-system definition.

Build 2 updates the font revision and version records without changing its
family or PostScript names. `manifest.json` records the checks and output hashes.

Install the generated `SahilMono-*.ttf` files in `~/Library/Fonts`, then select
**Sahil Mono** in Rex Settings → Terminal → Choose. Select **Light**, **17 pt**
to retain the settings in use when this font was installed. Reverting only
requires selecting the previous JetBrains font; no original font is replaced.
When replacing an earlier Sahil Mono build, quit and reopen Rex so its cached
glyphs and shaping results use the updated font files.
