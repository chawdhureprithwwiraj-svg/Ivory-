#!/usr/bin/env python3
"""
IVORY - PUT THE REAL SIGNATURE ON THE BUILD.

WHY THIS FILE EXISTS
--------------------
Every Android app is signed. Until now Ivory has been signed with
Flutter's DEBUG key - a throwaway key that is identical on every
machine in the world. It installs fine by sideloading, but:

  * Google Play will refuse it outright.
  * Anyone could build a fake "Ivory" that the phone treats as the
    same app, because they have the same key.

This file puts HER key on the build instead.

WHY IT IS NOT JUST A FILE IN THE REPO
-------------------------------------
Ivory has NO android/ folder on purpose. The workflow runs
`flutter create --platforms android` on every single build, which
means the Gradle files are born fresh each time and ANY signing
config committed to the repo would be wiped out before it was read.
So the config has to be injected AFTER that step, every build. That
is this script.

IT MUST NEVER BREAK A BUILD
---------------------------
If the four secrets are absent, this script says so and exits 0,
and the build carries on debug-signed exactly as before. That means
it can be merged today and the secrets added later, and a build at
any point in between still works. A signing script that can break
the only working build route is worse than no signing script.

THE KEYSTORE IS NEVER IN THE REPOSITORY. It arrives as a base64
GitHub Secret, is written outside the source tree's history, and is
never printed. If it leaks, nobody can ever publish a genuine
update to Ivory again - see the warnings in the signing sheet.

Usage:  python3 tools/ci_sign.py sign
"""
import base64
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(os.path.join(HERE, '..'))

STORE = 'android/app/ivory-release.jks'

KTS_LOAD = '''import java.io.FileInputStream
import java.util.Properties

// ---- Ivory: load the signing key, if one was supplied ----
val ivoryKeyProps = Properties()
val ivoryKeyFile = rootProject.file("key.properties")
if (ivoryKeyFile.exists()) {
    FileInputStream(ivoryKeyFile).use { ivoryKeyProps.load(it) }
}

'''

GROOVY_LOAD = '''// ---- Ivory: load the signing key, if one was supplied ----
def ivoryKeyProps = new Properties()
def ivoryKeyFile = rootProject.file("key.properties")
if (ivoryKeyFile.exists()) {
    ivoryKeyFile.withInputStream { ivoryKeyProps.load(it) }
}

'''

KTS_CONFIG = '''    signingConfigs {
        create("release") {
            keyAlias = ivoryKeyProps["keyAlias"] as String
            keyPassword = ivoryKeyProps["keyPassword"] as String
            storeFile = file(ivoryKeyProps["storeFile"] as String)
            storePassword = ivoryKeyProps["storePassword"] as String
        }
    }

'''

GROOVY_CONFIG = '''    signingConfigs {
        release {
            keyAlias ivoryKeyProps['keyAlias']
            keyPassword ivoryKeyProps['keyPassword']
            storeFile file(ivoryKeyProps['storeFile'])
            storePassword ivoryKeyProps['storePassword']
        }
    }

'''


def read(path):
    with open(path, encoding='utf-8') as fh:
        return fh.read()


def write(path, text):
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(text)


def app_gradle():
    for cand in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
        if os.path.exists(cand):
            return cand
    sys.exit('ERROR: no android/app/build.gradle(.kts) found')


def patch(text, kts):
    """Return the app Gradle file with release signing wired in.

    Three edits, each one checked for first so that running twice is
    harmless:
      1. load key.properties at the very top,
      2. declare a 'release' signingConfig,
      3. point the release build type at it instead of debug.
    """
    if 'ivoryKeyProps' in text:
        print('signing config already present - nothing to do')
        return text

    load = KTS_LOAD if kts else GROOVY_LOAD
    config = KTS_CONFIG if kts else GROOVY_CONFIG

    # 1. The loader goes at the very top. In a .kts file the import
    #    lines MUST come before anything else, including plugins {}.
    text = load + text

    # 2. The signingConfigs block goes just before buildTypes, which
    #    is inside the android {} block in every template Flutter has
    #    shipped.
    marker = '    buildTypes {'
    if marker not in text:
        sys.exit('ERROR: no buildTypes block found in the app Gradle '
                 'file. Flutter changed its template - the signing '
                 'patch needs updating.')
    text = text.replace(marker, config + marker, 1)

    # 3. Flutter's template points release at the DEBUG key, with a
    #    comment admitting it. Swap in the real one.
    swaps = [
        ('signingConfig = signingConfigs.getByName("debug")',
         'signingConfig = signingConfigs.getByName("release")'),
        ('signingConfig signingConfigs.debug',
         'signingConfig signingConfigs.release'),
    ]
    done = False
    for old, new in swaps:
        if old in text:
            text = text.replace(old, new, 1)
            done = True
    if not done:
        sys.exit('ERROR: could not find the debug signingConfig line '
                 'to replace. Refusing to produce a build that LOOKS '
                 'signed but is not.')
    return text


def cmd_sign():
    b64 = os.environ.get('KEYSTORE_BASE64', '').strip()
    store_pw = os.environ.get('KEYSTORE_PASSWORD', '')
    alias = os.environ.get('KEY_ALIAS', '')
    key_pw = os.environ.get('KEY_PASSWORD', '')

    if not b64:
        print('=' * 60)
        print('NO KEYSTORE SECRET FOUND.')
        print('This build will be signed with the throwaway DEBUG key,')
        print('exactly as every previous Ivory build has been. That is')
        print('fine for sideloading and NOT fine for Google Play.')
        print('To fix: add the four secrets listed in the signing')
        print('sheet, then run this workflow again.')
        print('=' * 60)
        return

    missing = [n for n, v in (('KEYSTORE_PASSWORD', store_pw),
                              ('KEY_ALIAS', alias),
                              ('KEY_PASSWORD', key_pw)) if not v]
    if missing:
        sys.exit('ERROR: KEYSTORE_BASE64 was supplied but these '
                 'secrets are missing: ' + ', '.join(missing) +
                 '. Add them and run again.')

    try:
        raw = base64.b64decode(b64, validate=True)
    except Exception:
        sys.exit('ERROR: KEYSTORE_BASE64 is not valid base64. It was '
                 'probably pasted with line breaks or spaces, or only '
                 'part of it was copied. Make it again with the '
                 'command in the signing sheet.')

    # A real keystore is a few kilobytes. Anything tiny is a truncated
    # paste, and catching it here is far clearer than a Gradle error.
    if len(raw) < 1000:
        sys.exit('ERROR: the decoded keystore is only %d bytes, which '
                 'is too small to be real. The secret was truncated '
                 'when it was pasted.' % len(raw))

    os.makedirs('android/app', exist_ok=True)
    with open(STORE, 'wb') as fh:
        fh.write(raw)
    print('keystore written: %s (%d bytes)' % (STORE, len(raw)))

    write('android/key.properties', '\n'.join([
        'storePassword=' + store_pw,
        'keyPassword=' + key_pw,
        'keyAlias=' + alias,
        'storeFile=ivory-release.jks',
        '',
    ]))
    print('android/key.properties written (contents not shown)')

    path = app_gradle()
    write(path, patch(read(path), path.endswith('.kts')))
    print('release signing wired into ' + path)
    print('THIS BUILD WILL BE SIGNED WITH THE IVORY RELEASE KEY.')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'sign':
        cmd_sign()
    else:
        sys.exit('usage: python3 tools/ci_sign.py sign')

# END OF FILE - tools/ci_sign.py
