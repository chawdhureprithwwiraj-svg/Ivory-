#!/usr/bin/env python3
"""Ivory - everything the GitHub Actions build does to android/.

Usage:  python3 tools/ci_android.py <command>
  verify   - required source files present and complete
  prepare  - permissions, <queries>, label, compileSdk 36 (raise only)
  firebase - copy google-services.json and wire the Gradle plugin
  icons    - put phone-renamed asset files back under exact names
"""

import glob
import os
import re
import shutil
import sys

MANIFEST = 'android/app/src/main/AndroidManifest.xml'
GMS_VERSION = '4.4.2'

REQUIRED = [
    'lib/main.dart',
    'lib/widgets/ivory_field.dart',
    'lib/theme/ivory_theme.dart',
    'lib/core/supabase_config.dart',
    'lib/models/ivory_profile.dart',
    'lib/models/media_ref.dart',
    'lib/models/ivory_post.dart',
    'lib/models/wish.dart',
    'lib/models/ivory_notification.dart',
    'lib/models/payment.dart',
    'lib/services/auth_service.dart',
    'lib/services/content_service.dart',
    'lib/services/wish_service.dart',
    'lib/services/notification_service.dart',
    'lib/services/payment_service.dart',
    'lib/widgets/post_card.dart',
    'lib/widgets/post_actions.dart',
    'lib/widgets/ivory_logo.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/main_shell.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/explore_screen.dart',
    'lib/screens/wish_screen.dart',
    'lib/screens/premium_screen.dart',
    'lib/screens/inbox_screen.dart',
    'lib/screens/checkout_screen.dart',
    'lib/screens/admin_screen.dart',
    'lib/screens/admin_payments_tab.dart',
    'pubspec.yaml',
]

# Installed only from the sprint that introduced the matching dependency.
GATED = [
    ('firebase_core', ['lib/services/push_service.dart']),
    ('agora_rtc_engine', [
        'lib/core/agora_config.dart',
        'lib/services/live_service.dart',
        'lib/screens/live_screen.dart',
        'lib/widgets/live_banner.dart',
        'lib/widgets/call_wish_sheet.dart',
        'lib/screens/wish_form.dart',
        'lib/models/live_models.dart',
        'lib/screens/admin_calls_tab.dart',
        'lib/screens/admin_live_tab.dart',
        'lib/widgets/live_chat.dart',
        'lib/screens/admin_members_tab.dart',
        'lib/widgets/post_unlock_sheet.dart',
        'lib/widgets/admin_post_chips.dart',
    ]),
    ('video_player', [
        'lib/widgets/ivory_media_view.dart',
        'lib/widgets/post_artwork.dart',
    ]),
    ('file_selector', [
        'lib/services/admin_service.dart',
        'lib/widgets/admin_bits.dart',
        'lib/widgets/member_pulse.dart',
        'lib/widgets/premium_badge.dart',
        'lib/screens/admin_create_tab.dart',
        'lib/screens/admin_library_list.dart',
        'lib/screens/admin_tiers_tab.dart',
        'lib/screens/admin_broadcast_tab.dart',
        'lib/screens/admin_wishes_tab.dart',
    ]),
]

# These end with a marker line, so a paste cut short is caught in seconds.
MARKED = [
    'lib/screens/login_screen.dart',
    'lib/widgets/post_unlock_sheet.dart',
    'lib/widgets/admin_post_chips.dart',
    'lib/screens/admin_create_tab.dart',
    'lib/screens/admin_members_tab.dart',
    'lib/models/live_models.dart',
    'lib/screens/admin_live_tab.dart',
    'lib/widgets/live_chat.dart',
    'lib/screens/admin_calls_tab.dart',
    'lib/screens/main_shell.dart',
    'lib/widgets/member_pulse.dart',
    'lib/services/live_service.dart',
    'lib/widgets/call_wish_sheet.dart',
    'lib/screens/wish_form.dart',
    'lib/screens/wish_screen.dart',
    'lib/screens/live_screen.dart',
    'lib/widgets/live_banner.dart',
    'lib/screens/home_screen.dart',
    'lib/widgets/ivory_media_view.dart',
    'lib/widgets/post_artwork.dart',
    'lib/widgets/post_card.dart',
    'lib/widgets/admin_bits.dart',
    'lib/screens/admin_create_tab.dart',
    'lib/screens/admin_library_list.dart',
    'lib/screens/admin_broadcast_tab.dart',
    'lib/screens/admin_wishes_tab.dart',
    'lib/screens/admin_screen.dart',
]

def read(path):
    return open(path, encoding='utf-8').read()

def write(path, text):
    open(path, 'w', encoding='utf-8').write(text)

# ----------------------------------------------------------------- verify

def cmd_verify():
    problems = 0
    pubspec = read('pubspec.yaml') if os.path.exists('pubspec.yaml') else ''

    needed = list(REQUIRED)
    for marker, files in GATED:
        if marker in pubspec:
            needed.extend(files)
            print('pubspec.yaml requests %s - those files are required.'
                  % marker)
        else:
            print('%s not installed yet - skipping its files.' % marker)

    for f in needed:
        if os.path.exists(f):
            print('found:', f)
        else:
            print('::error::MISSING FILE: %s - create it on GitHub before '
                  'building.' % f)
            problems += 1

    for f in MARKED:
        if os.path.exists(f):
            tail = read(f).strip().splitlines()[-3:]
            if not any('END OF FILE' in line for line in tail):
                print('::error::TRUNCATED PASTE: %s does not end with its '
                      'END OF FILE line. Paste it again.' % f)
                problems += 1

    if problems:
        sys.exit('%d problem(s) found.' % problems)
    print('All required files are present and complete.')

# ---------------------------------------------------------------- prepare

PERMISSIONS = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.POST_NOTIFICATIONS',
    # Agora live video and calls.
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.MODIFY_AUDIO_SETTINGS',
    'android.permission.ACCESS_WIFI_STATE',
    'android.permission.READ_PHONE_STATE',
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_CONNECT',
]

QUERIES = (
    '    <queries>\n'
    '        <intent>\n'
    '            <action android:name="android.intent.action.VIEW"/>\n'
    '            <data android:scheme="https"/>\n'
    '        </intent>\n'
    '        <intent>\n'
    '            <action android:name="android.intent.action.VIEW"/>\n'
    '            <data android:scheme="http"/>\n'
    '        </intent>\n'
    '        <intent>\n'
    '            <action android:name="android.intent.action.VIEW"/>\n'
    '            <data android:scheme="tg"/>\n'
    '        </intent>\n'
    '        <intent>\n'
    '            <action android:name="android.intent.action.VIEW"/>\n'
    '            <data android:scheme="upi"/>\n'
    '        </intent>\n'
    '    </queries>\n'
)

# Some plugins are still published against android-34, while newer ones
# refuse to be consumed below 36. Every module is lifted in one place.
KTS_BLOCK = """
// ---- Ivory: raise every module to compileSdk 36 (raise only) ----
// Inserted BEFORE Flutter's subprojects block. Newer targets stay.
subprojects {
    val raiseCompileSdk = fun(p: org.gradle.api.Project) {
        val ext = p.extensions.findByName("android") ?: return
        val methods = ext.javaClass.methods

        var current = 0
        try {
            val getter = methods.firstOrNull {
                it.name == "getCompileSdk" && it.parameterTypes.isEmpty()
            }
            val value = getter?.invoke(ext)
            if (value is Int) {
                current = value
            } else {
                val legacy = methods.firstOrNull {
                    it.name == "getCompileSdkVersion" &&
                        it.parameterTypes.isEmpty()
                }
                val text = legacy?.invoke(ext) as? String
                current = text?.removePrefix("android-")?.toIntOrNull() ?: 0
            }
        } catch (e: Exception) {
            current = 0
        }

        if (current >= 36) {
            p.logger.lifecycle("Ivory: " + p.name + " keeps compileSdk " +
                current)
            return
        }

        val setter = methods.firstOrNull {
            it.name == "setCompileSdk" && it.parameterTypes.size == 1
        } ?: methods.firstOrNull {
            it.name == "setCompileSdkVersion" &&
                it.parameterTypes.size == 1 &&
                it.parameterTypes[0] == Int::class.javaPrimitiveType
        }
        try {
            setter?.invoke(ext, 36)
            p.logger.lifecycle("Ivory: " + p.name + " raised " + current +
                " -> 36")
        } catch (e: Exception) {
            p.logger.lifecycle("Ivory: compileSdk untouched for " + p.name)
        }
    }
    if (state.executed) {
        raiseCompileSdk(this)
    } else {
        afterEvaluate { raiseCompileSdk(this) }
    }
}

"""

GROOVY_BLOCK = """
// ---- Ivory: give every module a modern compileSdk (raise only) ----
subprojects {
    def raiseCompileSdk = { proj ->
        def ext = proj.extensions.findByName('android')
        if (ext == null) {
            return
        }
        int current = 0
        try {
            def v = ext.compileSdkVersion
            if (v instanceof Integer) {
                current = v
            } else if (v instanceof String) {
                def digits = v.replaceAll('[^0-9]', '')
                current = digits ? digits.toInteger() : 0
            }
        } catch (Exception e) {
            current = 0
        }
        if (current >= 36) {
            return
        }
        try {
            ext.compileSdkVersion 36
        } catch (Exception e) {
            proj.logger.lifecycle("Ivory: compileSdk untouched")
        }
    }
    if (project.state.executed) {
        raiseCompileSdk(project)
    } else {
        project.afterEvaluate { raiseCompileSdk(it) }
    }
}

"""

def cmd_prepare():
    xml = read(MANIFEST)

    missing = [p for p in PERMISSIONS if p not in xml]
    if missing:
        block = ''.join(
            '    <uses-permission android:name="%s"/>\n' % p for p in missing)
        if '<application' not in xml:
            sys.exit('ERROR: no <application> tag in the manifest')
        xml = xml.replace('<application', block + '\n    <application', 1)
        print('Added:', ', '.join(missing))
    else:
        print('All permissions already present.')

    # url_launcher on Android 11+ can only see apps declared in <queries>.
    if '<queries>' not in xml:
        xml = xml.replace('<application', QUERIES + '\n    <application', 1)
        print('Added <queries> block for url_launcher.')

    # The label on <application> is what the launcher shows.
    def fix(match):
        tag = match.group(0)
        if 'android:label=' in tag:
            return re.sub(r'android:label="[^"]*"',
                          'android:label="Ivory"', tag)
        return tag.replace('<application',
                           '<application android:label="Ivory"', 1)

    xml = re.sub(r'<application[^>]*>', fix, xml, count=1)
    write(MANIFEST, xml)

    check = read(MANIFEST)
    assert 'android.permission.INTERNET' in check, 'INTERNET missing!'
    assert '<queries>' in check, '<queries> missing!'
    assert 'android:label="Ivory"' in check, 'app label not applied!'
    print('Manifest ready: permissions, queries and the Ivory label.')

    # ---- compileSdk 36 for every module ----
    root = None
    for cand in ('android/build.gradle.kts', 'android/build.gradle'):
        if os.path.exists(cand):
            root = cand
            break
    if root is None:
        sys.exit('ERROR: no android/build.gradle(.kts) found')

    text = read(root)
    if 'Ivory: raise every module' in text:
        print('compileSdk override already present in', root)
    else:
        block = KTS_BLOCK if root.endswith('.kts') else GROOVY_BLOCK
        # It MUST come before Flutter's own subprojects block: that one
        # calls evaluationDependsOn(":app"), and afterEvaluate cannot be
        # registered on an already-evaluated project.
        cut = text.find('subprojects')
        if cut == -1:
            cut = text.find('tasks.register')
        if cut == -1:
            text = text + block
            print('compileSdk 36 override appended to', root)
        else:
            text = text[:cut] + block + text[cut:]
            print('compileSdk 36 override inserted early in', root)
        write(root, text)

    for cand in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
        if os.path.exists(cand):
            t = read(cand)
            t = t.replace('compileSdk = flutter.compileSdkVersion',
                          'compileSdk = 36')
            t = t.replace('compileSdk flutter.compileSdkVersion',
                          'compileSdk 36')
            t = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion',
                       'minSdk = 23', t)
            t = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion',
                       'minSdkVersion 23', t)
            write(cand, t)
            print('app module: compileSdk 36, minSdk 23')
            break

# --------------------------------------------------------------- firebase

def cmd_firebase():
    if not os.path.exists('firebase/google-services.json'):
        print('::warning::firebase/google-services.json not found - the app '
              'will build WITHOUT device push.')
        return

    os.makedirs('android/app', exist_ok=True)
    shutil.copyfile('firebase/google-services.json',
                    'android/app/google-services.json')
    print('Copied google-services.json into android/app/')

    settings = None
    for cand in ('android/settings.gradle.kts', 'android/settings.gradle'):
        if os.path.exists(cand):
            settings = cand
            break
    if settings is None:
        sys.exit('ERROR: no android/settings.gradle(.kts) found')

    text = read(settings)
    if 'com.google.gms.google-services' not in text:
        if settings.endswith('.kts'):
            line = ('    id("com.google.gms.google-services") version "%s" '
                    'apply false\n' % GMS_VERSION)
        else:
            line = ("    id 'com.google.gms.google-services' version '%s' "
                    "apply false\n" % GMS_VERSION)
        m = re.search(r'plugins\s*\{', text)
        if not m:
            sys.exit('ERROR: no plugins block in ' + settings)
        text = text[:m.end()] + '\n' + line + text[m.end():]
        write(settings, text)
        print('Added the google-services plugin to', settings)

    app = None
    for cand in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
        if os.path.exists(cand):
            app = cand
            break
    if app is None:
        sys.exit('ERROR: no android/app/build.gradle(.kts) found')

    text = read(app)
    if 'com.google.gms.google-services' not in text:
        line = ('    id("com.google.gms.google-services")\n'
                if app.endswith('.kts')
                else "    id 'com.google.gms.google-services'\n")
        m = re.search(r'plugins\s*\{', text)
        if not m:
            sys.exit('ERROR: no plugins block in ' + app)
        text = text[:m.end()] + '\n' + line + text[m.end():]
        write(app, text)
        print('Applied the google-services plugin in', app)
    print('Firebase wired up.')

# ------------------------------------------------------------------ icons

def normalise(folder, target, must_contain, must_not_contain=()):
    dest = os.path.join(folder, target)
    if os.path.exists(dest):
        return
    for src in sorted(glob.glob(os.path.join(folder, '*.png'))):
        base = os.path.basename(src).lower()
        if any(bad in base for bad in must_not_contain):
            continue
        if all(good in base for good in must_contain):
            shutil.copyfile(src, dest)
            print('renamed %s -> %s' % (src, target))
            return

def cmd_icons():
    # pubspec declares both asset folders, so they must exist.
    for folder in ('assets/icon', 'assets/logo'):
        os.makedirs(folder, exist_ok=True)
        if not os.listdir(folder):
            open(os.path.join(folder, '.gitkeep'), 'w').close()

    # Phone browsers rename downloads to "ivory_icon (1).png" and the like.
    normalise('assets/icon', 'ivory_icon_bg.png', ['_bg'])
    normalise('assets/icon', 'ivory_icon_foreground.png', ['foreground'])
    normalise('assets/icon', 'ivory_icon.png', ['ivory_icon'],
              ['_bg', 'foreground'])
    normalise('assets/logo', 'ivory_logo.png', ['logo'])

    if not os.path.exists('assets/icon/ivory_icon.png'):
        print('::error::assets/icon/ivory_icon.png is missing - the launcher '
              'icon was NOT changed.')
        sys.exit(0)

    layers_ok = (os.path.exists('assets/icon/ivory_icon_foreground.png')
                 and os.path.exists('assets/icon/ivory_icon_bg.png'))
    if not layers_ok:
        print('::warning::Adaptive icon layers missing - plain icon only.')
        lines = read('pubspec.yaml').splitlines(True)
        write('pubspec.yaml',
              ''.join(l for l in lines if 'adaptive_icon_' not in l))
        print('Removed adaptive_icon_* from pubspec.yaml for this build.')
    print('ICON_READY')

COMMANDS = {
    'verify': cmd_verify,
    'prepare': cmd_prepare,
    'firebase': cmd_firebase,
    'icons': cmd_icons,
}

if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] not in COMMANDS:
        sys.exit('usage: ci_android.py %s' % '|'.join(COMMANDS))
    COMMANDS[sys.argv[1]]()

# END OF FILE - tools/ci_android.py
