#!/usr/bin/env python3
"""
IVORY - SWITCH THE SCREENS' TEXT TO THE TRANSLATING TEXT, WHILE BUILDING.

WHY THIS FILE EXISTS
--------------------
Every word on an Ivory screen is a Flutter `Text(...)`. To show those words in
the member's language without editing about 150 screen files by hand, the build
robot does one small, mechanical change on its own temporary copy of the code:
in each member screen it swaps

    import 'package:flutter/material.dart';
for
    import 'package:flutter/material.dart' hide Text;
    import '<path>/l10n/ui_text.dart';      (a twin of Text that translates)

Nothing in your repository is changed. The change exists only inside the build.

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


def say(md):
    path = os.environ.get('GITHUB_STEP_SUMMARY')
    if path:
        with open(path, 'a', encoding='utf-8') as fh:
            fh.write(md + '\n')
    print(md)


def apply():
    if not os.path.exists(HOOK):
        say('Screen translation: %s is not in the repository, so nothing was changed.' % HOOK)
        return
    changed = 0
    for root, _dirs, names in os.walk('lib'):
        for name in sorted(names):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(root, name).replace(os.sep, '/')
            if any(part in path for part in SKIP):
                continue
            with open(path, encoding='utf-8') as fh:
                text = fh.read()
            if text.count(MATERIAL) != 1 or 'ui_text.dart' in text:
                continue
            if OTHERS.search(text) or not USES_TEXT.search(text):
                continue
            rel = os.path.relpath(HOOK, os.path.dirname(path)).replace(os.sep, '/')
            text = text.replace(
                MATERIAL,
                "import 'package:flutter/material.dart' hide Text;\nimport '%s';" % rel, 1)
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(text)
            changed += 1
    say('Screen translation: %d screen files now use the translating text.' % changed)


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
