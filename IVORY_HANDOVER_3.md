# IVORY - HANDOVER, PART 4

Sprint 24j onward. Part 3 (`IVORY_HANDOVER_3.md`, same folder) holds
the history: who built what, the bug register B1-B10, the call chain
design, the 6 October decisions, and the 24a-24i ledger. Read Part 3
first, then this. Neither file is read by the app; both are letters to
the next agent.

Current to **7 October 2026, 15:40 IST**.

---

## J. CURRENT STATE AT HANDOVER (7 Oct 2026, 03:50 IST)

**Closed:** B1, B2, B3, B4, B5, B8, B9. Part 1 (admin CREATE) is fully
working: story, audio, video (incl. 65.6 MB via Vault), image, priced
posts, and polls all publish.
**Open:** B6 (two call-sheet leak sites remain), Parts 2 & 3 (call chain)
untouched. **Part 1 and Part 4 of Sprint 24 are complete.**

**Working method, owner's instruction 7 Oct:** batch **4-5 files per
build** rather than one. Small blocks are still right; one CI build per
single-line change is not.

**Next block: 24k** - the in-app player for link-only posts, so `WATCH
NOW` never leaves Ivory. Then the call chain (Parts 2 & 3), which is all
that remains of Sprint 24.

### J.1 Poll feed card - how it works
`post_card.dart` now routes `PostType.poll` straight to
`PollCard` (`lib/widgets/poll_card.dart`) before any artwork logic. The
card loads its own options, lets a member **vote without leaving the
feed**, shows at most 4 options (`_maxInFeed`) with "N more options" and
an *Open* link to the sheet. Failures render as a quiet line, never a raw
error. The older `PostType.poll` branches further down `post_card.dart`
are now unreachable; they are harmless and were left alone.

---

## K. STORAGE - WHERE EVERY FILE LIVES (from 24j)

| Kind | Home | Why |
|---|---|---|
| Film, any size | **Cloudflare R2** | 10 GB free, **zero egress**. |
| Voice note | **Cloudflare R2** | Same. Moved in 24j. |
| Photograph | Supabase Storage, public | **Decided 7 Oct**, see K.2. |
| Cover image | Supabase Storage, public | Same reason, and they are tiny. |
| Pasted link | Nowhere | Stored as given. |

Rules live in **`lib/screens/admin_publish_media.dart`** - one function,
`resolvePublishMedia()`. Change storage policy there and nowhere else.

### K.1 `VaultService.uploadBytes()` - new in 24j
`uploadVideo()` streams a **path** (a film must never be read into a 4 GB
phone's memory). `uploadBytes()` does the same presign-then-PUT journey for
something already held as bytes, sliced at 256 KB so the progress line
moves. Both return a vault key stored with `media_source = 'r2'`;
`open_post` signs a GET per member, re-checking `can_open_post`.

**Trap:** an R2 key must *never* be cached in `at.setUploadedUrl()`. That
field is for public URLs. Cache a key there and a retried publish files it
as a Supabase object, handing the member a dead link.

### K.2 DECIDED 7 Oct - photographs stay on Supabase

The owner asked for everything on R2; audio and video moved, photographs
did not. She was shown the reason and **ruled: leave photos where they
are.**

Why: the feed paints a photo from a **public URL, synchronously**. An R2
object has **no public URL**, so every photo would need an edge signature
first - a twenty-card feed means twenty extra round trips before anything
appears. Films and voice notes escape this because they are opened one at
a time and `open_post` signs them on the way in. Photographs are also
small, so the 1 GB Supabase allowance will last.

Rejected alternatives, recorded so they are not re-litigated: a **custom
domain on the R2 bucket** (makes objects publicly readable - the privacy
is no worse than today, but it is work for no gain while photos are
small); and **batch-signing a whole feed page** in one new edge op (most
private, most work - revisit only if photo volume ever threatens the
Supabase quota).

### K.3 `admin_create_tab.dart` had hit the ceiling
It reached 18,681 B against an 18,432 B limit. Comments were already lean
(24 lines in 555), so it was **split**, not shaved: the upload logic moved
out whole to `admin_publish_media.dart`. The composer is now 16.3 KB / 498
lines. **Do not let it grow back - split again instead.**

### K.4 - The dead-import trap (cost one build, 7 Oct)

Splitting the composer in 24j I dropped `import
'../services/vault_service.dart'` after grepping only for `VaultService`.
Build failed: `admin_create_tab.dart:221:10: Error: 'VaultFullError' isn't
a type`. That file exports **two** public names; the upload moved out, the
catch stayed. Import restored, marked `// Do not remove`.

**Rule:** before deleting an import, grep for *every* class, enum and
typedef that file declares. A checker resolving every capitalised
identifier in `lib/` against its declaring file now runs before each
delivery; it confirmed `media_ref.dart` really is unused.

## L. SPRINT 24k (7 Oct) + WHAT 24l MUST DO

### L.1 A story may carry a file - fixed

`post_actions.dart` split the sheet by post type: `blog` went to
`_ReaderBody` (words only), everything else to `_MediaBody`. A story
with a film uploaded fine, reached R2, showed in the Vault - and
nothing drew it. Not a crash; an assumption that a story is always
text.

`_StoryMedia` renders under the writing. It cannot use `post.type`
(that says `blog`), so it reads the **file extension** off the stored
ref, falling back to the signed URL with the query stripped. Silent
when there is no file - a wordless story is normal, not an error.

### L.2 Poll bars are burgundy

Fills `#6B1527 -> #96344A`, lead `burgundy -> #72203A`, gold stop edge
kept. **The trap:** the label is painted *over* the bar in burgundy -
invisible on wine. `_words(ink, accent)` is drawn twice, the second
copy ivory inside `ClipRect(clipper: _LeftFraction(f))`, clipped to
the bar edge. Identical layout both times or the glyphs drift.
`AnimatedFractionallySizedBox` became `TweenAnimationBuilder` so bar
and clip animate off one value. Own answer ringed **amber**; plum
vanished on wine.

### L.3 `tools/dart_check.py` - run before every delivery

    python3 tools/dart_check.py [file ...]

Brace/paren balance, `const` constructors using the runtime colour
getters, and every capitalised identifier resolved against a reachable
import. Its predecessor stripped strings with one regex and cried wolf:
an apostrophe inside `"Ivory's Golden Reserve"` opened a string that
never closed; it tokenises properly now. Known pre-existing noise:
`checkout_screen`, `live_screen`, `call_wish_sheet` exceed 18 KB, and
the older files have no sentinel.

### L.4 24l - "Ivory must watch first" (NOT yet built)

Owner wants a curated shelf on Home, **up to 25 posts, any mix of
types**. Never call it "pinned" in member-facing copy.

**"Ivory's Golden Reserve" is not a feature.** `home_screen.dart:57` is
`_featured` = the first unlocked non-poll post. No admin control. The
shelf replaces that guess with the owner's choice.

Needs: `pin_rank int` on posts (null = unpinned), surfaced through
`post_previews` - **drop and recreate the view, trap 11.8**; a cap of 25
enforced in Postgres, not the client; a toggle in
`admin_library_list.dart`; a horizontal rail on Home above the Recent
section. Idempotent SQL.

---

## M. IVORY'S FIRSTLIST (24l shipped, 24m pending)

**The name is "Ivory's Firstlist".** Owner's choice, 7 Oct. Never write
"pinned" anywhere a member can read it. Up to **25** posts, any mix of
types.

### M.1 What 24l put in

`sprint24l_firstlist.sql` - idempotent, run and reported 5 rows.

* `posts.pin_rank integer` - NULL means not on the list, 1 means first.
  Partial index on the non-null rows.
* `set_firstlist(post_id_in bigint, pinned_in boolean) -> integer`
  checks `profiles.role = 'admin'`, enforces the cap, appends at
  `max(pin_rank) + 1`. Re-pinning is a no-op returning its place.
* `firstlist_ids() -> (post_id, place)` - the admin Library's stars.
* `firstlist() -> setof post_previews` - the member shelf, for 24m.

**The cap of 25 is enforced in Postgres, never in the client.** A rule
living only in Dart is not a rule; the REST API is reachable without
the app. The refusal is `P0001` with a sentence written for a person,
and `houseMessage()` passes `P0001` through untouched - so she reads
"Ivory's Firstlist already holds 25 posts...", not an error code.

### M.2 Why the view was left alone

`firstlist()` returns **`setof public.post_previews`**, inheriting
whatever columns that view has, now and later. Dropping and
recreating `post_previews` was rejected: its definition is not
visible from the app source, and rebuilding it blind could silently
drop a column and kill the feed. `security invoker` keeps the view's
entitlement rules, so the shelf can never reveal a post the ordinary
feed would hide.

### M.3 Admin control

`admin_library_list.dart` - a gold star per row, left of the live
switch. It moves on tap and rolls back if the database refuses.
`_firstlist` is re-read from `firstlist_ids()` on every load, never
guessed. If that call fails the Library still renders, stars dark.

### M.4 The shelf - 24m, shipped

`ContentService.fetchFirstlist()` calls `rpc('firstlist')` and maps
through `IvoryPost.fromPreview`. It **swallows its errors and returns
an empty list**: one unreadable shelf must never take Home down.

`FirstlistRail` (`lib/widgets/firstlist_rail.dart`, new): a sideways
shelf of 182 x 232 cards - poster or warm panel with the kind icon, a
gold numbered disc for the place, a LOCKED pill when shut. Tapping
goes through `PostActions.open`, so locked posts behave as in the
feed.

`home_screen.dart`: `_load()` fetches feed and shelf together with
`Future.wait`. **The shelf must be its own query** - the feed pulls
only the newest 12 and a Firstlist post is often older. `_recent`
subtracts what the shelf shows, so nothing prints twice.

**"Ivory's Golden Reserve" was never a feature.** `_featured` is just
the first unlocked non-poll post; no admin control ever existed. The
Firstlist takes that slot when it has entries, and Golden Reserve
returns by itself if the list is ever emptied, so Home is never bare.

### M.5 Not built

Re-ordering. `pin_rank` is `max + 1` on adding, so the order is the
order she starred things; changing it means unstar and re-star. A
drag handle needs `reorder_firstlist(bigint[])` rewriting every rank
in one transaction.

---

## N. HOW A POST ARRIVES ON SCREEN (24n)

Owner, 7 Oct: the detail card "doesn't reach the top, shows from the
mid level down". She was right, and the cause was two numbers in
`post_actions.dart`: `initialChildSize: 0.78, maxChildSize: 0.96`. It
opened low and **could never reach the top** - dragged fully, 4% of
feed still showed. It read as stuck rather than deliberate.

**Decision: adaptive, by content.**

* **Read or listened to** - story, voice note, poll - is a sheet that
  **opens full (1.0)**. Corners square, status-bar gap open. It can be
  thrown down to 0.62 to peek at the feed, or closed by the cross.
* **Watched or looked at** - video, image - takes the **whole screen**
  at once, via a route, not a sheet.

**24n first shipped at 0.94 and that was wrong.** The owner had to drag
every post up before she could see it. A tap means open; nothing
belongs between the tap and the thing itself.

`lib/widgets/post_surface.dart` (new) owns all of it:
`IvoryPostSurface.show(context, child, immersive: bool)`.
`PostActions._sheet` is now a three-line forwarder.

### N.1 Three traps in that file

* **Use `viewPadding.top`, NEVER `padding.top`.** Cost two builds; the
  writing printed over the clock both times. `padding` is zeroed twice
  before this code sees it: `main_shell.dart:143` wraps the whole app
  in a **`SafeArea`**, which consumes the inset and removes it for
  every descendant, and `useSafeArea: false` on the sheet strips the
  top padding again. Neither touches **`viewPadding`**, which is the
  physical status bar and cutout. `useSafeArea: false` itself is
  deliberate - true would stop the sheet short of the top, the very
  bug being fixed - so the gap is opened by hand inside instead.
* The close cross is always visible; a way out must never have to be
  discovered.
* **The extent is read from `DraggableScrollableNotification`**, not a
  controller, and only rebuilds past a 0.004 change. Without that
  guard it calls `setState` on every animation frame of the snap.
* **New file on purpose** - `post_actions.dart` was 16.6 KB and this
  logic would have pushed it past the 18 KB ceiling.

### N.2 How a written story is laid out (24o)

A story is not words with a file bolted on. `_ReaderBody._flow()`
splits the body into paragraphs and places `_StoryMedia` **after the
first one**, so the opening lines lead, the film or photograph arrives
early, and the rest of the writing continues beneath it.

* **24k buried the file.** It fixed "the attachment is invisible" by
  drawing it under the writing - which meant a 3,000 character story
  hid the film completely until a member had scrolled past everything.
  Fixing a thing's absence is not the same as placing it.
* **Paragraphs are split on blank lines, falling back to single
  breaks** when she writes without blank lines. Either typing style
  gives real paragraphs; neither ever yields one unbroken slab.
* A single-paragraph story behaves exactly as before - the file lands
  after it, which is also the end.
* **There is no length limit anywhere and none may be added.** The
  composer body has `maxLines: 14` (box height, not a cap), no
  `maxLength`, and the column is Postgres `text`. The owner asked for
  unlimited and it is already true - do not "helpfully" truncate, and
  do not add a "read more": a tap opens the whole story.
* The gold hairline under the handle is the reading position, driven
  by a `ValueNotifier` so a scroll does not rebuild the sheet. It
  hides itself below 600 px of scroll, where it would always read
  full.

## O. EDITING A POST - DESIGNED, NOT YET BUILT

**There is no update path anywhere in Ivory.** `admin_service` can
create, price, publish, delete - nothing can change a word. The only
fix today is delete and repost, which is dangerous:

* `publish_post` **fires the announce trigger**, so a repost pushes a
  notification to every member for something they already read.
* Views, poll votes and **every purchase of that post** die with the
  row. A member who paid 199 for "Again" would be locked out of the
  replacement, with nothing recording it.
* The post loses its place on Ivory's Firstlist.

Editing is a guard on member money, not a convenience. Owner agreed it
outranks the call chain.

### O.1 Rules the implementation must hold

1. **An edit must never notify.** The trigger fires on insert; the
   edit must be a true `UPDATE` of the same row without tripping it.
   Read the trigger before writing the RPC.
2. **Same post id, always** - that is what keeps views, votes,
   purchases and the Firstlist place alive.
3. **The replaced file is not deleted** (owner's standing rule), but
   it eats the 9 GB cap, so the editor must say so and offer
   MANAGE VAULT.
4. **Post type is not editable** - it chooses the detail view.
5. **Poll options freeze once a vote exists.**

### O.2 Shape

**One form, not two.** Reuse `admin_attach_panel`,
`admin_post_chips`, `resolvePublishMedia` rather than a parallel
screen that will drift. `admin_create_tab` is 16.3 KB, so the editor
is its own screen built from those shared pieces. Owner's scope:
title, teaser, body, cover, the media file, tiers and price.

<!-- END OF FILE - IVORY_HANDOVER_4.md -->
