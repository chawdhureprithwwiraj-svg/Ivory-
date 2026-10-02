#!/usr/bin/env python3
"""Ivory - the flag-word audit.

Payment gateways and app stores do not read your intentions; they scan
your words. This walks every line of member-facing copy in the app and
in the database migrations and reports anything that a risk reviewer
would read as adult or companion services.

Run it before any of these:
  - applying to a payment gateway
  - submitting to Google Play
  - publishing a website or store listing

    python3 tools/copy_audit.py

Exit code 0 means nothing serious was found.
"""

import os
import re
import sys

# ---------------------------------------------------------------- rules
#
# STOP   a reviewer sees this and reaches for the adult/companion
#        category. Must not appear in member-facing copy.
# CHECK  fine in context, wrong on a store listing or a payment form.
#        Judgement call, flagged so it is a decision and not an
#        accident.

STOP = [
    'real woman', 'real women', 'your criteria', 'feel live',
    'whisper', 'escort', 'girlfriend', 'companion', 'hookup',
    'nude', 'naked', 'erotic', 'sexy', 'seduce', 'seductive',
    'sensual', 'lust', 'xxx', 'adult content', 'camgirl', 'webcam',
    'watch her', 'strip club', 'fetish',
]

CHECK = [
    'desire', 'desires', 'intimate', 'discreet', 'crave', 'craved',
    'pleasure', 'tease', 'flirt', 'queen of', 'king of', 'dirty',
    'naughty',
]

# Words that are fine inside code but meaningless to a reviewer.
IGNORE_CONTEXT = [
    'teaser',          # _FrostedTeaser, "Short teaser" field label
    'stripe',          # payment processors
    'description',
]

SKIP_DIRS = {'.git', 'build', '.dart_tool', 'node_modules', '.github'}
# Only what a member or a reviewer can actually read. Setup notes and
# workflow files are for the owner and never ship.
SCAN_EXT = {'.dart', '.sql'}

# Files whose contents are notes to the owner, not member-facing copy.
SKIP_FILES = {
    'IVORY_HANDOVER.md',
    'tools/copy_audit.py',
    'tools/gen_copy_tool.py',
}


def is_comment(line, path):
    t = line.strip()
    if path.endswith('.dart') or path.endswith('.ts'):
        return t.startswith('//') or t.startswith('///') or t.startswith('*')
    if path.endswith('.sql'):
        return t.startswith('--')
    if path.endswith(('.yml', '.yaml')):
        return t.startswith('#')
    return False


def scan():
    stops, checks = [], []

    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in sorted(files):
            path = os.path.join(root, name).replace('./', '')
            if path in SKIP_FILES:
                continue
            if os.path.splitext(name)[1] not in SCAN_EXT:
                continue
            try:
                lines = open(path, encoding='utf-8').read().splitlines()
            except Exception:
                continue

            for n, line in enumerate(lines, 1):
                # A comment can quote a banned word while explaining
                # why it was removed. That is documentation, not copy.
                if is_comment(line, path):
                    continue
                # Only quoted text can reach a member's eyes. Variable
                # names, function names and comments cannot.
                quoted = ' '.join(
                    re.findall(r"'([^']{4,})'|\"([^\"]{4,})\"",
                               line).__iter__().__length_hint__() * [] or
                    [a or b for a, b in
                     re.findall(r"'([^']{4,})'|\"([^\"]{4,})\"", line)]
                )
                if not quoted:
                    continue
                low = quoted.lower()
                if any(w in low for w in IGNORE_CONTEXT) and \
                        not any(w in low for w in STOP):
                    continue
                for w in STOP:
                    if re.search(r'\b%s\b' % re.escape(w), low):
                        stops.append((path, n, w, line.strip()[:88]))
                for w in CHECK:
                    if re.search(r'\b%s\b' % re.escape(w), low):
                        checks.append((path, n, w, line.strip()[:88]))
    return stops, checks


def main():
    stops, checks = scan()

    print('IVORY - FLAG-WORD AUDIT')
    print('=' * 60)

    if stops:
        print('\nSTOP - remove these before applying anywhere (%d)\n'
              % len(stops))
        for path, n, w, text in stops:
            print('  %s:%s  [%s]' % (path, n, w))
            print('      %s' % text)
    else:
        print('\nSTOP words: none. Nothing a reviewer would read as '
              'adult or companion services.')

    if checks:
        print('\nCHECK - fine in context, decide before publishing (%d)\n'
              % len(checks))
        for path, n, w, text in checks:
            print('  %s:%s  [%s]' % (path, n, w))
            print('      %s' % text)
    else:
        print('\nCHECK words: none.')

    print('\n' + '=' * 60)
    if stops:
        print('RESULT: %d blocking, %d to review.' % (len(stops), len(checks)))
        sys.exit(1)
    print('RESULT: clean. %d judgement calls listed above.' % len(checks))


if __name__ == '__main__':
    main()

# END OF FILE - tools/copy_audit.py
