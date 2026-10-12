#!/usr/bin/env python3
"""Static checks for Ivory's private B2 client path and any checked-in backend source.

This repository's owner deploys SQL and Edge Functions directly in Supabase.
Those server files are therefore optional here and are not prerequisites for
building the Android APK. Client-side B2 safeguards remain checked below.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def read_optional(path: str) -> str | None:
    file_path = ROOT / path
    if not file_path.is_file():
        return None
    return file_path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)
    print("PASS:", message)


def skip(message: str) -> None:
    print("SKIP:", message)


# These are actual Android source dependencies and remain required.
publish = read("lib/screens/admin_publish_media.dart")
panel = read("lib/screens/admin_attach_panel.dart")
choice = read("lib/widgets/admin_storage_choice.dart")
content = read("lib/services/content_service.dart")
service = read("lib/services/b2_media_service.dart")
workflow = read(".github/workflows/build_apk.yml")
pubspec = read("pubspec.yaml")

# The owner deploys these in the Supabase Dashboard, not in GitHub.
edge = read_optional("supabase/functions/b2-media/index.ts")
schema = read_optional("supabase_schema.sql")
migration = read_optional("sql/cc114_private_b2_media.sql")
function_config = read_optional("supabase/config.toml")

if edge is None:
    skip("B2 Edge Function source is Dashboard-managed, not stored in GitHub; it is not an APK build input.")
else:
    require('B2_BUCKET = "ivory-post-media-b2-2026"' in edge,
            "uses the existing B2 bucket by name")
    require(all(token not in edge for token in ("CreateBucket", "PutBucketAcl", "public-read")),
            "does not create a bucket or change bucket visibility")
    require('env("B2_KEY_ID")' in edge and
            'env("B2_APPLICATION_KEY")' in edge,
            "B2 credentials are read only from server-side secrets")
    require('can_open_post' in edge and 'open_post' in edge,
            "temporary reader links repeat post entitlement checks")
    require('SUPABASE_PUBLISHABLE_KEYS' in edge and
            'SUPABASE_ANON_KEY' in edge and
            'auth.getUser(token)' in edge,
            "supports current Supabase API keys and explicitly validates user JWTs")
    require('if (!userId && body.op !== "get" && body.op !== "sign_previews")' in edge,
            "anonymous B2 previews are allowed only through existing entitlement checks")
    require('if (!userId) return json' in edge and 'profile.role !== "admin"' in edge,
            "storage uploads and usage remain restricted to a validated admin")
    require('post.is_published === true' in edge,
            "drafts cannot receive reader preview links")
    require('sign_previews' in edge and '3600' in edge,
            "feed previews use temporary signed links")

if function_config is None:
    skip("supabase/config.toml is not checked in; Dashboard function settings remain authoritative.")
else:
    require('[functions.b2-media]' in function_config and
            'verify_jwt = false' in function_config,
            "B2 function config records in-code JWT validation")
    require('[functions.business-enquiry]' in function_config and
            'verify_jwt = false' in function_config,
            "business-enquiry config records in-code JWT validation")

require("type == 'image'" in publish and "? 'b2'" in publish,
        "new post photos default to private B2")
require("String? mediaProvider;" in panel and
        "widget.initialMediaProvider == 'r2'" in panel and
        "mediaChoice == null" in publish and
        "Choose R2 or B2" in choice and
        "mediaProvider ?? 'r2'" not in publish,
        "new video/voice uploads require an explicit per-post provider choice")
require("imageChoice == 'r2' && isPublished ? 'r2' : 'b2'" in publish,
        "an R2-selected photo still routes privately while it is a draft")
require("desiredThumb = imageChoice == 'r2' && isPublished ? 'r2' : 'b2'" in publish,
        "draft covers cannot be uploaded to public R2")
require("String imageProvider = 'b2'" in panel and
        "allowPublicR2: widget.isPublished" in panel,
        "composer defaults covers to B2 and hides public R2 for drafts")
require("R2 - public to anyone with the link" in choice,
        "the app labels the R2 image choice as public")
require("openPostMedia(id)" in content and "signPreviewUrls(ids)" in content,
        "full posts and feed covers request B2 signing")
require("B2MediaService" in service and "b2-media" in service,
        "Flutter uploads and signs through the Supabase Edge Function")

if schema is not None and migration is not None:
    require("'b2'" in schema and "'b2'" in migration,
            "database source checks allow B2 media and covers")
    require("update public.posts" not in migration.lower(),
            "migration does not rewrite or migrate existing media")
else:
    skip("B2 SQL/schema source is managed in Supabase and is not stored in GitHub; SQL checks are separate from APK compilation.")

require("flutter build apk --release" in workflow and "--split-per-abi" not in workflow,
        "keeps the existing single-APK build command")
require("workflow_dispatch:" in workflow and "push:" in workflow and
        "branches: [main]" in workflow,
        "preserves the existing automatic build on a main push")
require("B2_KEY_ID" not in workflow and "B2_APPLICATION_KEY" not in workflow,
        "does not put B2 secrets in the APK build workflow")
require("version: 1.5.0+37" in pubspec,
        "checks the current Android build number")

print("Private B2 APK-side acceptance checks passed.")

# END OF FILE - tools/b2_media_check.py
