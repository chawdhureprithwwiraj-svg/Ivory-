#!/usr/bin/env python3
"""Static acceptance checks for Ivory's host-camera beauty and Phase 2 UI."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)
    print("PASS:", message)


service = read("lib/services/live_beauty_service.dart")
panel = read("lib/widgets/live_beauty_panel.dart")
live = read("lib/screens/live_screen_beauty_part.dart")
preview = read("lib/screens/admin_live_beauty_preview.dart")
home = read("lib/screens/home_screen.dart")
explore = read("lib/widgets/explore_everything_cta.dart")
profile = read("lib/screens/profile_screen.dart")
main_shell = read("lib/screens/main_shell.dart")
member_form = read("lib/screens/business_enquiry_screen.dart")
enquiry_service = read("lib/services/business_enquiry_service.dart")
admin_inbox = read("lib/screens/admin_business_enquiries_tab.dart")
function = read("supabase/functions/business-enquiry/index.ts")
sql = read("sql/business_enquiries.sql")
config = read("supabase/config.toml")
pubspec = read("pubspec.yaml")
workflow = read(".github/workflows/build_apk.yml")

require(
    "this.redness = 0.0" in service
    and "'redness': redness" in service
    and "redness: _number(json['redness'], 0.0, 1.0)" in service,
    "rosiness persists locally and safely defaults to zero",
)
require(
    "rednessLevel: value.enabled ? value.redness : 0" in service
    and "title: 'Rosiness'" in panel,
    "rosiness uses Agora's existing basic option and is optional",
)
require(
    "widget.mode == LiveMode.host &&" in live
    and "final bool cameraMode = widget.mode == LiveMode.host;" in live
    and "LiveMode.call" not in live,
    "beauty controls remain limited to the owner's host-broadcast path",
)
require(
    "whole camera image" in panel.lower()
    and "background" in panel.lower()
    and "pimples" in panel.lower(),
    "the panel explains whole-image lightening and does not promise spot removal",
)
require(
    "backgroundColor: IvoryColors.gold" in preview
    and "foregroundColor: IvoryColors.burgundy" in preview,
    "the pre-live Adjust Beauty control has high-contrast text",
)
require(
    "ExploreEverythingCta(onTap: () => _go('explore'))" in home
    and "InkWell(" in explore
    and "MediaQuery.of(context).disableAnimations" in explore,
    "Explore Everything is a clickable CTA that respects reduced-motion settings",
)
require(
    "Expanded(" in profile
    and "maxLines: 2" in profile
    and "padding: const EdgeInsets.only(top: 10)" in profile,
    "the profile name and ID have flexible space above the membership badge",
)
require(
    "functions.invoke(" in enquiry_service
    and "business-enquiry" in enquiry_service
    and "BUSINESS_ENQUIRY_TO" not in member_form + enquiry_service + main_shell,
    "members submit through the server function without seeing the destination email",
)
require(
    "auth.getUser(token)" in function
    and "RESEND_API_KEY" in function
    and "BUSINESS_ENQUIRY_TO" in function
    and "BUSINESS_ENQUIRY_FROM" in function
    and "email_status: emailStatus" in function,
    "the server authenticates, stores, and records private email-notification status",
)
require(
    "business_enquiries_owner_read" in sql
    and "business_enquiries_owner_mark_read" in sql
    and "public.is_admin()" in sql
    and "verify_jwt = false" in config,
    "the enquiry table is owner-only and the function validates the user in code",
)
require(
    "class AdminBusinessEnquiriesTab" in admin_inbox
    and "AdminBusinessEnquiriesTab()" in read("lib/screens/admin_screen.dart")
    and "initialTab: 10" in main_shell
    and "Tab(text: 'ENQUIRIES')" in read("lib/screens/admin_screen.dart"),
    "the owner has an in-app inbox route and an Enquiries admin tab",
)
require(
    "version: 1.5.0+37" in pubspec
    and "flutter build apk --release" in workflow
    and "--split-per-abi" not in workflow,
    "the patch retains the existing one-universal-APK workflow",
)

print("Phase 2 static acceptance checks passed.")

# END OF FILE - tools/beauty_phase1_check.py
