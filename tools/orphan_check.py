#!/usr/bin/env python3
"""
ORPHAN CHECK - the blind spot that broke sprint 27c.

dart_check.py counts brackets and bytes. It cannot see that a
method was LEFT BEHIND when a widget was lifted into a new
file, because the file it checks is still perfectly balanced.
That is exactly how call_allowance_card.dart shipped calling a
_dmy() that did not travel with it.

This reads every file in lib/ and reports any call to a
PRIVATE method that is not defined in the same file. A private
name cannot cross a file boundary in Dart, so every hit is
either a real build error or a mention inside a comment.

IT DOES NOT CATCH PUBLIC NAMES. wishIcon() lived in a screen
and the lifted widget simply had to import it - no private
name involved, nothing for this tool to see. After a lift,
ALSO grep each new file for every bare identifier it calls.

RUN IT AFTER EVERY LIFT. It takes under a second.
"""

import glob
import os
import re
import sys

CALL = re.compile(r'(?<![\w.])(_[A-Za-z]\w*)\s*\(')
CLS = re.compile(r'class\s+(_\w+)')
VAR = re.compile(r'(_[A-Za-z]\w*)\s*=\s*\(')
FLD = re.compile(r'(_[A-Za-z]\w*)\s*[;,=]')


def definitions(src):
    """Every private name that is DEFINED here.

    A regex cannot do this. The first version used [^;]* for the
    parameter list, which ran across newlines and read a CALL
    like

        _doorStamp(post),
        ...
      ) {

    as a definition - which is exactly why this tool said "no
    orphans" about a tree that had two. Tightening the regex
    then broke the opposite way and missed every signature
    written across several lines.

    So: find each occurrence, walk the brackets to the matching
    close paren, and look at what comes next. A definition is
    followed by '{' or '=>'. A call is followed by anything
    else. No guessing.
    """
    found = set(CLS.findall(src)) | set(VAR.findall(src))
    found |= set(FLD.findall(src))

    for match in CALL.finditer(src):
        index = src.index('(', match.end() - 1)
        depth = 0
        while index < len(src):
            if src[index] == '(':
                depth += 1
            elif src[index] == ')':
                depth -= 1
                if depth == 0:
                    break
            index += 1

        tail = src[index + 1:index + 40].lstrip()
        if tail.startswith('async'):
            tail = tail[5:].lstrip()
        if tail.startswith('{') or tail.startswith('=>'):
            found.add(match.group(1))

    return found


def strip_comments(src: str) -> str:
    """A name mentioned in a comment is not a call."""
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    return '\n'.join(
        line for line in src.split('\n')
        if not line.lstrip().startswith('//'))


def main() -> int:
    all_paths = sorted(glob.glob('lib/**/*.dart', recursive=True))
    paths = sys.argv[1:] or all_paths
    raw_by_path = {}
    parent_by_path = {}
    for path in all_paths:
        with open(path, encoding='utf-8') as handle:
            raw_by_path[path] = handle.read()
        part = re.search(r"^part of '([^']+\.dart)'", raw_by_path[path], re.M)
        parent_by_path[path] = (
            os.path.normpath(os.path.join(os.path.dirname(path), part.group(1)))
            if part else path
        )
    problems = 0

    for path in paths:
        parent = parent_by_path.get(path, path)
        members = [p for p in all_paths if parent_by_path[p] == parent]
        combined = strip_comments('\n'.join(raw_by_path[p] for p in members))

        used = set(CALL.findall(combined))
        missing = sorted(used - definitions(combined))
        if missing:
            problems += 1
            print(path)
            for name in missing:
                print('    calls %s() - not defined in this file' % name)

    if problems:
        print('\n%d file(s) with an orphaned private call.' % problems)
        return 1

    print('%d file(s) checked. No orphans.' % len(paths))
    return 0


if __name__ == '__main__':
    sys.exit(main())

# END OF FILE - tools/orphan_check.py
