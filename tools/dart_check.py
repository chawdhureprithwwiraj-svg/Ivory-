"""Structural checks for Ivory's Dart files, run before every delivery.

The sandbox cannot compile Flutter, so these are the only checks that
happen before a four minute CI build. They catch the three mistakes
that have actually cost builds on this project:

  1. unbalanced braces/parens from a bad paste or a bad edit
  2. a runtime colour getter used inside a `const` constructor
  3. a class used without an import that reaches its declaration

An earlier version of this stripped strings with a single regex and
reported phantom errors, because an apostrophe inside a double quoted
string ("Ivory's Golden Reserve") opened a string that never closed.
It is a real tokenizer now.

    python3 tools/dart_check.py [file ...]      # default: all of lib/
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
os.chdir(ROOT)

# Colour members of IvoryColors that are `static Color get`, not const.
RUNTIME_COLOURS = ('textSoft', 'textFaint', 'hairline', 'hairlineStrong')


def strip(src):
    """Blank out comments and string bodies, keeping length and newlines.

    Handles // line comments, /* block */ comments, single and double
    quotes, raw strings, triple quotes and backslash escapes. Brace and
    paren counting is only trustworthy on the output of this.
    """
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        two = src[i:i + 2]
        if two == '//':
            j = src.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        elif two == '/*':
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(''.join(ch if ch == '\n' else ' ' for ch in src[i:j]))
            i = j
        elif c in '"\'':
            raw = i > 0 and src[i - 1] == 'r'
            triple = src[i:i + 3] in ('"""', "'''")
            close = src[i:i + 3] if triple else c
            j = i + len(close)
            while j < n:
                if not raw and src[j] == '\\':
                    j += 2
                    continue
                if src[j:j + len(close)] == close:
                    j += len(close)
                    break
                j += 1
            out.append(''.join(ch if ch == '\n' else ' ' for ch in src[i:j]))
            i = j
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def const_misuse(src, code):
    """Find `const Something( ... IvoryColors.textFaint ... )`.

    Walks forward from each `const` keyword to the matching close paren
    rather than using a regex, so a nested call cannot drag the match
    across half the file.
    """
    hits = []
    for m in re.finditer(r'\bconst\s+[A-Z]\w*\s*\(', code):
        depth, j = 0, m.end() - 1
        while j < len(code):
            if code[j] == '(':
                depth += 1
            elif code[j] == ')':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        span = src[m.start():j]
        for name in RUNTIME_COLOURS:
            if re.search(r'IvoryColors\.' + name + r'\b', span):
                line = src.count('\n', 0, m.start()) + 1
                hits.append('line %d: const %s uses IvoryColors.%s'
                            % (line, m.group(0).strip(), name))
    return hits


def declarations():
    found = {}
    for base, _, names in os.walk('lib'):
        for name in names:
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            text = open(path, encoding='utf-8').read()
            pattern = (r'^(?:abstract\s+)?(?:class|enum|mixin|extension'
                       r'|typedef)\s+(\w+)')
            for m in re.finditer(pattern, text, re.M):
                found.setdefault(m.group(1), set()).add(path)
    return found


# ---------------------------------------------------------------
# DUPLICATE LIFECYCLE METHODS INSIDE ONE CLASS.
#
# Added after `wish_screen.dart` shipped with TWO initState()
# methods in the same class. Dart refuses to compile that, and
# **every other check in this file passed it**: brackets
# balanced, sentinel present, under the ceiling, no orphans. The
# sheet went out and her build could not possibly have worked.
#
# A patch that INSERTS a lifecycle method can always collide
# with one already there, and in a 400-line file the collision
# is invisible by eye. So it is checked here rather than
# remembered.
#
# Deliberately narrow: ONLY the handful of methods a State or
# widget may declare exactly once. Trying to catch every
# duplicate member meant mistaking `SizedBox(` inside a build
# tree for a declaration - a checker that cries wolf gets
# ignored, which is worse than no checker.
# ---------------------------------------------------------------
ONCE_ONLY = (
    'initState',
    'dispose',
    'build',
    'didUpdateWidget',
    'didChangeDependencies',
    'createState',
    'deactivate',
)


def duplicate_members(path, text):
    """Report a lifecycle method declared twice in one class."""
    problems = []
    lines = text.split('\n')
    # Where each top-level class starts.
    heads = [i for i, l in enumerate(lines)
             if re.match(r'^(?:abstract\s+)?class\s+\w+', l)]
    for n, head in enumerate(heads):
        end = heads[n + 1] if n + 1 < len(heads) else len(lines)
        name = re.match(r'^(?:abstract\s+)?class\s+(\w+)',
                        lines[head]).group(1)
        body = lines[head:end]
        for method in ONCE_ONLY:
            hits = [head + j + 1 for j, l in enumerate(body)
                    if re.match(r'^  (?:\w[\w<>,\.\?\s]*\s+)?'
                                + method + r'\s*\(', l)]
            if len(hits) > 1:
                problems.append(
                    'class %s declares %s() %d times (lines %s) - '
                    'DART WILL NOT COMPILE THIS'
                    % (name, method, len(hits),
                       ', '.join(str(h) for h in hits)))
    return problems


def main():
    targets = sys.argv[1:]
    if not targets:
        targets = []
        for base, _, names in os.walk('lib'):
            targets += [os.path.join(base, f)
                        for f in sorted(names) if f.endswith('.dart')]

    decls = declarations()
    problems = 0

    for path in targets:
        src = open(path, encoding='utf-8').read()
        code = strip(src)
        notes = []

        for label, (a, b) in {'{}': ('{', '}'), '()': ('(', ')'),
                              '[]': ('[', ']')}.items():
            diff = code.count(a) - code.count(b)
            if diff:
                notes.append('UNBALANCED %s by %+d' % (label, diff))

        notes += const_misuse(src, code)

        # A file that is imported also brings in whatever it
        # EXPORTS. ivory_theme.dart re-exports ivory_colors.dart,
        # so `import 'ivory_theme.dart'` legitimately reaches
        # IvoryColors. Without this the checker reported 79
        # failures that were all the same false alarm - and a
        # checker that cries wolf is worse than no checker,
        # because the real fault hides in the noise.
        imports = {os.path.normpath(os.path.join(os.path.dirname(path), m))
                   for m in re.findall(r"import '([^':]+\.dart)'", src)}
        imports.add(path)
        part = re.search(r"^part of '([^']+\.dart)'", src, re.M)
        if part:
            library = os.path.normpath(
                os.path.join(os.path.dirname(path), part.group(1)))
            imports.add(library)
            if os.path.exists(library):
                library_src = open(library, encoding='utf-8').read()
                imports.update(
                    os.path.normpath(os.path.join(os.path.dirname(library), m))
                    for m in re.findall(
                        r"import '([^':]+\.dart)'", library_src))
        for step in range(4):
            grown = set(imports)
            for f in imports:
                if not os.path.exists(f):
                    continue
                for m in re.findall(r"export '([^':]+\.dart)'",
                                    open(f, encoding='utf-8').read()):
                    grown.add(os.path.normpath(
                        os.path.join(os.path.dirname(f), m)))
            if grown == imports:
                break
            imports = grown
        body = re.sub(r'^import[^\n]*\n', '', code, flags=re.M)
        for sym in sorted(set(re.findall(r'\b([A-Z]\w+)\b', body))):
            if sym in decls and not decls[sym] & imports:
                notes.append('NO IMPORT REACHES %s (declared in %s)'
                             % (sym, ', '.join(sorted(decls[sym]))))

        tail = '// END OF FILE - ' + path
        if not src.rstrip().endswith(tail):
            notes.append('MISSING OR WRONG SENTINEL (want "%s")' % tail)
        if src.count('END OF FILE') != 1:
            notes.append('SENTINEL APPEARS %d TIMES'
                         % src.count('END OF FILE'))

        size = len(src.encode('utf-8'))
        if size > 18 * 1024:
            notes.append('OVER THE PASTE CEILING: %d bytes' % size)

        notes.extend(duplicate_members(path, src))

        if notes:
            problems += len(notes)
            print('%s  (%d B)' % (path, size))
            for note in notes:
                print('    ' + note)

    if problems:
        print('\n%d problem(s).' % problems)
        return 1
    print('%d file(s) checked. Clean.' % len(targets))
    return 0


if __name__ == '__main__':
    sys.exit(main())

# END OF FILE - tools/dart_check.py
                              
