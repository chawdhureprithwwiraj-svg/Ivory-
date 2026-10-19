#!/usr/bin/env python3
"""
IVORY - SWITCH THE SCREENS' TEXT TO THE TRANSLATING TEXT, WHILE BUILDING.

WHY THIS FILE EXISTS
--------------------
Every word on an Ivory screen is a Flutter `Text(...)`. To show those words in
the member's language without editing about 150 screen files by hand, the build
robot does small, mechanical changes on its own temporary copy of the code.

STEP 1 (CC.152). In each member screen it swaps
    import 'package:flutter/material.dart';
for
    import 'package:flutter/material.dart' hide Text;
    import '<path>/l10n/ui_text.dart';      (a twin of Text that translates)

STEP 2 (CC.153). Labels, hints and tooltips are plain strings, not `Text`:
    labelText: 'Your story'      becomes      labelText: 'Your story'.uiTr
Where such a string sits inside a `const` widget, the word `const` is removed
from that widget (it is only a speed-up, never needed for the app to work).
If the Dart analyzer then reports an error in a file, that file's step-2
changes are undone on the spot; if errors remain, all of step 2 is undone.

Nothing in your repository is changed. The changes exist only inside the build.

IT MUST NEVER BREAK A BUILD
---------------------------
The workflow checks the result with the Dart analyzer. If it finds any error,
it runs `revert` and the app is built in plain English as before. Deleting
tools/ci_l10n.on switches the whole thing off.

Usage:  python3 tools/ci_l10n.py apply | revert
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(os.path.join(HERE, '..'))

HOOK = 'lib/l10n/ui_text.dart'
MATERIAL = "import 'package:flutter/material.dart';"
# Left alone on purpose: admin screens (the House reads English), the language
# files, main, the footer, the legal wording and the sign-in screens (which
# already speak the chosen language).
SKIP = ('admin', 'l10n/', 'main.dart', 'house_consent', 'legal_screen',
        'ivory_footer', 'login_screen', 'language_')
OTHERS = re.compile(r"import\s+'package:flutter/(widgets|cupertino)\.dart'")
USES_TEXT = re.compile(r'\bText(\.rich)?\(')

# Step 2: the named arguments whose plain-string values are shown to members.
LABEL_KEYS = ('labelText', 'hintText', 'helperText', 'helpText', 'tooltip', 'message')
KEY_BEFORE = re.compile(r'\b(?:%s)\s*:\s*$' % '|'.join(LABEL_KEYS))
AFTER_OK = re.compile(r'\s*[,)]')
CONST_CALL = re.compile(
    r'\bconst\s+[A-Za-z_][\w.]*\s*(?:<[^<>;(){}]*(?:<[^<>;(){}]*>[^<>;(){}]*)*>)?\s*$')
CONST_COLL = re.compile(
    r'\bconst\s*(?:<[^<>;(){}]*(?:<[^<>;(){}]*>[^<>;(){}]*)*>)?\s*$')
ERROR_LINE = re.compile(r'^\s*error\s+•\s+.*•\s+(\S+\.dart):(\d+):(\d+)\s+•')


def say(md):
    path = os.environ.get('GITHUB_STEP_SUMMARY')
    if path:
        with open(path, 'a', encoding='utf-8') as fh:
            fh.write(md + '\n')
    print(md)


def read(path):
    with open(path, encoding='utf-8') as fh:
        return fh.read()


def write(path, text):
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(text)


# ---------------------------------------------------------------- step 1
def step1():
    done = []
    for root, _dirs, names in os.walk('lib'):
        for name in sorted(names):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(root, name).replace(os.sep, '/')
            if any(part in path for part in SKIP):
                continue
            text = read(path)
            if text.count(MATERIAL) != 1 or 'ui_text.dart' in text:
                continue
            if OTHERS.search(text) or not USES_TEXT.search(text):
                continue
            rel = os.path.relpath(HOOK, os.path.dirname(path)).replace(os.sep, '/')
            text = text.replace(
                MATERIAL,
                "import 'package:flutter/material.dart' hide Text;\nimport '%s';" % rel, 1)
            write(path, text)
            done.append(path)
    return done


# ---------------------------------------------------------------- step 2
def skip_string(s, i):
    """s[i] is a quote (or the r of a raw string). Returns the index after it."""
    raw = False
    if s[i] == 'r' and i + 1 < len(s) and s[i + 1] in '\'"':
        raw = True
        i += 1
    q = s[i]
    n = len(s)
    if s.startswith(q * 3, i):
        j = s.find(q * 3, i + 3)
        return n if j < 0 else j + 3
    j = i + 1
    while j < n:
        c = s[j]
        if c == q:
            return j + 1
        if c == '\n':
            return j
        if c == '\\' and not raw:
            j += 2
            continue
        if c == '$' and not raw and j + 1 < n and s[j + 1] == '{':
            depth, j = 1, j + 2
            while j < n and depth:
                if s[j] in '\'"':
                    j = skip_string(s, j)
                    continue
                if s[j] == '{':
                    depth += 1
                elif s[j] == '}':
                    depth -= 1
                j += 1
            continue
        j += 1
    return n


def scan(s):
    """Returns (masked, strings): the code with comments and string contents
    blanked out (same length), and every plain string as (start, end)."""
    out = list(s)
    strings = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c == '/' and s.startswith('//', i):
            j = s.find('\n', i)
            j = n if j < 0 else j
            out[i:j] = ' ' * (j - i)
            i = j
            continue
        if c == '/' and s.startswith('/*', i):
            j = s.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out[i:j] = ' ' * (j - i)
            i = j
            continue
        starts = c in '\'"' or (c == 'r' and i + 1 < n and s[i + 1] in '\'"' and
                                (i == 0 or not (s[i - 1].isalnum() or s[i - 1] == '_')))
        if starts:
            j = skip_string(s, i)
            strings.append((i, j))
            out[i:j] = ' ' * (j - i)
            i = max(j, i + 1)
            continue
        i += 1
    return ''.join(out), strings


def consts_around(masked, pos):
    """Positions of every explicit `const` of the widgets that enclose pos."""
    found = []
    depth = 0
    i = pos - 1
    while i >= 0:
        c = masked[i]
        if c in ')]}':
            depth += 1
        elif c in '([{':
            if depth > 0:
                depth -= 1
            else:
                lo = max(0, i - 220)
                head = masked[lo:i]
                m = (CONST_CALL if c == '(' else CONST_COLL).search(head)
                if m:
                    found.append(lo + m.start())
        i -= 1
    return found


def step2_file(text):
    """Returns (new_text, sites, consts_removed) for one file."""
    masked, strings = scan(text)
    edits = {}      # position -> ('ins', str) | ('del', length)
    sites = 0
    for k, (a, b) in enumerate(strings):
        lit = text[a:b]
        if len(lit) < 4 or lit[-1] not in '\'"' or '\n' in lit:
            continue
        if lit.startswith(("'''", '"""')) or not re.search(r'[A-Za-z]', lit):
            continue
        if not KEY_BEFORE.search(masked[max(0, a - 40):a]):
            continue
        if not AFTER_OK.match(text, b):
            continue
        sites += 1
        edits[b] = ('ins', '.uiTr')
        for p in consts_around(masked, a):
            edits[p] = ('del', 5)
    removed = sum(1 for v in edits.values() if v[0] == 'del')
    for pos in sorted(edits, reverse=True):
        kind, val = edits[pos]
        if kind == 'ins':
            text = text[:pos] + val + text[pos:]
        else:
            end = pos + val
            while end < len(text) and text[end] in ' \t':
                end += 1
            text = text[:pos] + text[end:]
    return text, sites, removed


def analyze_errors():
    """{file: [(line, col)]} from the Dart analyzer; None if it cannot run."""
    try:
        res = subprocess.run(['flutter', 'analyze', '--no-pub', 'lib'],
                             capture_output=True, text=True, timeout=1200)
    except Exception:
        return None
    bad = {}
    for line in (res.stdout + '\n' + res.stderr).splitlines():
        m = ERROR_LINE.match(line)
        if m:
            bad.setdefault(m.group(1).replace('\\', '/'), []).append(
                (int(m.group(2)), int(m.group(3))))
    return bad


def step2(files):
    before = {}     # file -> text after step 1
    sites = removed = 0
    for path in files:
        text = read(path)
        new, n, r = step2_file(text)
        if n:
            before[path] = text
            write(path, new)
            sites += n
            removed += r
    if not before:
        return
    if os.environ.get('IVORY_L10N_NO_ANALYZE'):
        say('Labels and hints (test run): %d sites, %d const words removed, %d files.'
            % (sites, removed, len(before)))
        return

    def undo(paths):
        for p in paths:
            if p in before:
                write(p, before[p])

    bad = analyze_errors()
    if bad is None:
        undo(list(before))
        say('Labels and hints: the analyzer could not run, so they stay English.')
        return
    if bad:
        undo([p for p in bad])
        bad2 = analyze_errors()
        if bad2:
            undo(list(before))
            say('Labels and hints: left in English (the check found errors).')
            return
        kept = len(before) - len([p for p in bad if p in before])
        say('Labels and hints: switched in %d files; %d files kept English.'
            % (kept, len(bad)))
        return
    say('Labels and hints: %d places in %d files now translate (%d const words removed).'
        % (sites, len(before), removed))


def apply():
    if not os.path.exists(HOOK):
        say('Screen translation: %s is not in the repository, so nothing was changed.' % HOOK)
        return
    files = step1()
    say('Screen translation: %d screen files now use the translating text.' % len(files))
    try:
        step2(files)
    except Exception as exc:        # never let step 2 stop step 1
        say('Labels and hints: skipped (%s).' % type(exc).__name__)
        subprocess.run(['git', 'checkout', '--', 'lib'], check=False)
        step1()


def revert():
    subprocess.run(['git', 'checkout', '--', 'lib'], check=False)
    say('Screen translation: switched back to plain text.')


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'apply':
        apply()
    elif cmd == 'revert':
        revert()
    else:
        sys.exit('usage: python3 tools/ci_l10n.py apply | revert')

# END OF FILE - tools/ci_l10n.py
