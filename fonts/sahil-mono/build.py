#!/usr/bin/env python3
"""Build Sahil Mono's default alternates without remapping Unicode glyphs.

Requires fonttools==4.68.0 and uharfbuzz==0.57.0. Keep Rex Ligatures ON:
this font deliberately carries the chosen substitutions in default-on calt.
"""
import argparse
from copy import deepcopy
import hashlib
import itertools
import json
from pathlib import Path
import shutil
import subprocess

from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import DecomposingRecordingPen
import uharfbuzz as hb

UPSTREAM_COMMIT = '19371302b95d218af43299bce79ddbddd0bc364d'
FEATURES = ('ss02', 'cv03', 'cv04', 'cv08', 'cv14', 'cv15', 'cv16',
            'cv18', 'cv19', 'cv20', 'zero')
LANGUAGES = (None, 'nl', 'tr', 'ro', 'el', 'ru')
EXAMPLES = ('&&', '&', '&&&', '$', '$$', '!=', '!==', '==', '===', '->',
            '=>', '<=', '>=', '::', ':', '//', '/*', '*/', 'www', '@', '&|',
            '1:2', 'a:b', 'a&&b', 'a->b', '<!--', '<!-- -->', '<!DOCTYPE',
            'https://example.com/a?x=1&y=2', 'g j K k $ & Q 026985 t l m W w f')
ASCII_PAIRS = tuple(''.join(p) for p in itertools.product(
    map(chr, range(32, 127)), repeat=2))
BUILD_VERSION = 2


def variants(font):
    records = font['GSUB'].table.FeatureList.FeatureRecord
    selected = sorted({i for r in records if r.FeatureTag in FEATURES
                       for i in r.Feature.LookupListIndex})
    mappings = []
    for index in selected:
        lookup = font['GSUB'].table.LookupList.Lookup[index]
        if lookup.LookupType != 1 or lookup.LookupFlag != 0:
            raise ValueError(f'Unsupported variant lookup {index}')
        mapping = {}
        for subtable in lookup.SubTable:
            for source, target in subtable.mapping.items():
                if source in mapping and mapping[source] != target:
                    raise ValueError(f'Conflicting variant for {source}')
                mapping[source] = target
        mappings.append(mapping)
    bases = {name for table in font['cmap'].tables if table.isUnicode()
             for name in table.cmap.values()}
    result = {}
    for base in sorted(bases):
        target = base
        for mapping in mappings:
            target = mapping.get(target, target)
        if target != base:
            result[base] = target
    return result


def outlines(font):
    glyphs = font.getGlyphSet()
    result = {}
    for name in font.getGlyphOrder():
        pen = DecomposingRecordingPen(glyphs)
        glyphs[name].draw(pen)
        result[name] = (pen.value, font['hmtx'].metrics[name])
    return result


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def shape(font, glyphs, text, features, language):
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    if language:
        buf.language = language
    hb.shape(font, buf, features)
    return [(glyphs[i.codepoint], i.cluster, p.x_advance, p.y_advance,
             p.x_offset, p.y_offset)
            for i, p in zip(buf.glyph_infos, buf.glyph_positions)]


def hbfont(path):
    font = hb.Font(hb.Face(path.read_bytes()))
    hb.ot_font_set_funcs(font)
    return font


def build(source, output):
    font = TTFont(source, recalcTimestamp=False)
    records = font['GSUB'].table.FeatureList.FeatureRecord
    tags = {r.FeatureTag for r in records}
    missing = (set(FEATURES) | {'calt'}) - tags
    if missing:
        raise ValueError(f'{source.name}: missing {sorted(missing)}')
    selected = {i for r in records if r.FeatureTag in FEATURES
                for i in r.Feature.LookupListIndex}
    # Refuse a source whose calt has different script/language visibility.
    for script in font['GSUB'].table.ScriptList.ScriptRecord:
        systems = [script.Script.DefaultLangSys]
        systems += [r.LangSys for r in script.Script.LangSysRecord]
        for system in filter(None, systems):
            indices = list(system.FeatureIndex)
            if system.ReqFeatureIndex != 0xFFFF:
                indices.append(system.ReqFeatureIndex)
            visible = {records[i].FeatureTag for i in indices}
            if 'calt' in visible and not set(FEATURES) <= visible:
                raise ValueError(f'{source.name}: incompatible script {script.ScriptTag}')
    for record in records:
        if record.FeatureTag == 'calt':
            record.Feature.LookupListIndex = sorted(
                set(record.Feature.LookupListIndex) | selected)
            record.Feature.LookupCount = len(record.Feature.LookupListIndex)
    replacements = variants(font)
    glyf = font['glyf']
    snapshots = {name: deepcopy(glyf[name]) for name in font.getGlyphOrder()}
    metrics = dict(font['hmtx'].metrics)
    referenced = {component.glyphName for glyph in snapshots.values()
                  if glyph.isComposite() for component in glyph.components}
    backups = {name: f'{name}.sahil-original' for name in replacements
               if name in referenced}
    order = list(font.getGlyphOrder())
    if set(backups.values()) & set(order):
        raise ValueError('Private original glyph names already exist')
    for name, backup in backups.items():
        glyf[backup] = deepcopy(snapshots[name])
        font['hmtx'].metrics[backup] = metrics[name]
        order.append(backup)
    font.setGlyphOrder(order)
    # Components must retain their original outlines when a base glyph changes.
    for name in order:
        glyph = glyf[name]
        if glyph.isComposite():
            for component in glyph.components:
                component.glyphName = backups.get(component.glyphName,
                                                  component.glyphName)
    for base, target in replacements.items():
        glyph = deepcopy(snapshots[target])
        if glyph.isComposite():
            for component in glyph.components:
                component.glyphName = backups.get(component.glyphName,
                                                  component.glyphName)
        glyf[base] = glyph
        font['hmtx'].metrics[base] = metrics[target]
    outlines(font)
    font['head'].fontRevision = 2.306
    # Preserve legacy weight grouping/style names and all license/author records.
    for record in font['name'].names:
        if record.nameID in (1, 3, 4, 6, 16, 18, 21, 25):
            value = record.toUnicode().replace('JetBrains Mono', 'Sahil Mono')
            value = value.replace('JetBrainsMono', 'SahilMono')
            font['name'].setName(value, record.nameID, record.platformID,
                                 record.platEncID, record.langID)
    for record in font['name'].names:
        if record.nameID in (3, 5):
            value = record.toUnicode().replace('2.305', '2.306')
            value = f'{value}; Sahil Mono build {BUILD_VERSION}'
            font['name'].setName(value, record.nameID, record.platformID,
                                 record.platEncID, record.langID)
    font.save(output)
    font.close()


def verify(source, output):
    original, custom = TTFont(source), TTFont(output)
    replacements = variants(original)
    dutch = [r.LangSys for script in original['GSUB'].table.ScriptList.ScriptRecord
             if script.ScriptTag == 'latn' for r in script.Script.LangSysRecord
             if r.LangSysTag == 'NLD ']
    records = original['GSUB'].table.FeatureList.FeatureRecord
    if len(dutch) != 1 or dutch[0].ReqFeatureIndex != 0xFFFF or {
            records[i].FeatureTag for i in dutch[0].FeatureIndex} != {'locl'}:
        raise AssertionError(f'{source.name}: unexpected Dutch feature visibility')
    for tag in original.keys():
        if tag not in ('GlyphOrder', 'name', 'GSUB', 'head', 'glyf', 'loca',
                       'hmtx', 'maxp', 'post'):
            if original.reader[tag] != custom.reader[tag]:
                raise AssertionError(f'{source.name}: unexpected change to {tag}')
    for name in original['name'].names:
        if name.nameID not in (1, 3, 4, 5, 6, 16, 18, 21, 25):
            match = custom['name'].getName(name.nameID, name.platformID,
                                           name.platEncID, name.langID)
            if match.toUnicode() != name.toUnicode():
                raise AssertionError(f'{source.name}: changed name {name.nameID}')
    old_outlines, new_outlines = outlines(original), outlines(custom)
    for name in original.getGlyphOrder():
        expected = old_outlines[replacements.get(name, name)]
        if new_outlines[name] != expected:
            raise AssertionError(f'{source.name}: wrong outline/metrics for {name}')
    if original.reader['cmap'] != custom.reader['cmap']:
        raise AssertionError(f'{source.name}: Unicode mappings changed')
    codepoints = sorted(original.getBestCmap())
    cases = [chr(cp) for cp in codepoints] + list(EXAMPLES) + list(ASCII_PAIRS)
    of, cf = hbfont(source), hbfont(output)
    og, cg = original.getGlyphOrder(), custom.getGlyphOrder()
    expected_flags = {tag: True for tag in FEATURES}
    expected_flags['calt'] = True
    dutch_baked_glyphs = 0
    for language in LANGUAGES:
        for text in cases:
            expected = shape(of, og, text, expected_flags, language)
            actual = shape(cf, cg, text, {'calt': True}, language)
            if expected != actual:
                raise AssertionError(f'{source.name}: mismatch {language=} {text!r}\n'
                                     f'{expected}\n{actual}')
            for old, new in zip(expected, actual):
                old_name = old[0]
                # Upstream Dutch exposes only locl; baked defaults still apply.
                if language == 'nl':
                    old_name = replacements.get(old_name, old_name)
                    dutch_baked_glyphs += old_name != old[0]
                if old_outlines[old_name] != new_outlines[new[0]]:
                    raise AssertionError(f'{source.name}: shaped outline mismatch '
                                         f'{language=} {text!r} {old[0]}')
    metadata = {'family': custom['name'].getDebugName(1),
                'style': custom['name'].getDebugName(2),
                'typographic_family': custom['name'].getDebugName(16),
                'typographic_style': custom['name'].getDebugName(17),
                'postscript_name': custom['name'].getDebugName(6),
                'weight': custom['OS/2'].usWeightClass,
                'italic': bool(custom['OS/2'].fsSelection & 1)}
    direct_glyph_checks = len(original.getGlyphOrder())
    original.close()
    custom.close()
    return {'source': source.name, 'output': output.name,
            'source_sha256': sha(source), 'sha256': sha(output),
            'unicode_cases': len(codepoints), 'ascii_pairs': len(ASCII_PAIRS),
            'example_cases': len(EXAMPLES), 'cases_per_language': len(cases),
            'total_cases': len(cases) * len(LANGUAGES), 'mismatches': 0,
            'baked_base_glyphs': len(replacements),
            'direct_glyph_checks': direct_glyph_checks,
            'dutch_baked_glyph_occurrences': dutch_baked_glyphs,
            'metadata': metadata}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path,
                        default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path,
                        default=Path(__file__).resolve().parent / 'dist')
    args = parser.parse_args()
    root, destination = args.source_root.resolve(), args.output.resolve()
    commit = subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'],
                                     text=True).strip()
    if commit != UPSTREAM_COMMIT:
        raise ValueError(f'Expected upstream {UPSTREAM_COMMIT}, got {commit}')
    sources = sorted((root / 'fonts' / 'ttf').glob('JetBrainsMono-*.ttf'))
    if len(sources) != 16:
        raise ValueError(f'Expected 16 static faces, found {len(sources)}')
    destination.mkdir(parents=True, exist_ok=True)
    report = {'family': 'Sahil Mono', 'upstream_commit': commit,
              'upstream': 'https://github.com/JetBrains/JetBrainsMono',
              'features': FEATURES, 'build_version': BUILD_VERSION,
              'method': 'bake base outlines and merge selected GSUB lookups into calt',
              'requires_calt': True, 'languages': LANGUAGES,
              'comparison': 'glyph names, outlines, metrics, clusters, advances and offsets',
              'dutch_geometry': 'baked base variants apply despite locl-only LangSys; '
                                'glyph names, positions and localized substitutions retained',
              'faces': []}
    for source in sources:
        output = destination / source.name.replace('JetBrainsMono', 'SahilMono')
        build(source, output)
        report['faces'].append(verify(source, output))
        print(f'PASS {output.name}', flush=True)
    shutil.copy2(root / 'OFL.txt', destination / 'OFL.txt')
    (destination / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'Validated {sum(f["total_cases"] for f in report["faces"]):,} cases; '
          f'manifest: {destination / "manifest.json"}', flush=True)


if __name__ == '__main__':
    main()
