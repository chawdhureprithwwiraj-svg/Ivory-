# IVORY - HANDOVER, PART 4

Sprint 24j onward. Part 3 (`IVORY_HANDOVER_3.md`, same folder) holds
the history: who built what, the bug register B1-B10, the call chain
design, the 6 October decisions, and the 24a-24i ledger. Read Part 3
first, then this. Neither file is read by the app; both are letters to
the next agent.

Current to **7 October 2026, 18:20 IST**.

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

* **Do not ask MediaQuery for the status bar height here. Ask the
  window.** This cost three builds. `padding.top` is zeroed twice -
  `main_shell.dart:143` wraps the app in a **`SafeArea`**, and
  `useSafeArea: false` strips it again - and `viewPadding.top` was
  measured on device returning **zero as well**. The only number that
  survives is `View.of(context).padding.top / devicePixelRatio`, the
  physical window, which no ancestor widget can alter. See
  `_statusBarHeight()`. It takes the larger of the window and the
  tree and floors the result at 24 - the floor is a guard against
  another silent zero, not a measurement. `useSafeArea: false` itself
  is deliberate: true stops the sheet short of the top, which is the
  bug it was meant to fix.
* **`Column` centres its children; it does not stretch them.** The
  handle row needs `width: double.infinity` or the `SizedBox` shrinks
  to the 44 px handle and `Positioned(right: 6)` lands the close
  cross in the middle of the handle instead of the screen edge. It
  shipped that way once and looked like a deliberate design.
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

## O. EDITING A POST (24p - BUILT)

Before this, the only way to fix a typo was delete and repost, which
re-notified all 45 members, reset the views, dropped the poll votes,
lost the Firstlist place and **orphaned every paid unlock** - a member
who paid 199 for "Again" would have been locked out with no record.
Editing is a guard on member money, not a convenience.

### O.1 The two triggers on public.posts - READ THIS FIRST

```
trg_notify_new_post        AFTER INSERT -> notify_new_post()
trg_notify_post_published  AFTER UPDATE OF is_published
                           WHEN new.is_published IS TRUE
                           AND old.is_published IS DISTINCT FROM true
                           -> notify_new_post()
```

**That WHEN clause is load bearing. Never remove it.** It is the only
reason editing is safe: `update_post` never inserts, so the first
trigger cannot fire, and on a post that is already live
`old.is_published` is already true, so the second fails its condition
and nobody is told. Only a real draft -> live flip announces, which is
correct. Note `UPDATE OF is_published` fires when the column is
**mentioned**, changed or not - the WHEN is what saves it, not care
over the SET list.

### O.2 What was built

* **`sprint24p_update_post.sql`** - `update_post(...)` returns bigint,
  `security definer`, gated on **`public.is_admin()`** (a FUNCTION;
  calling it as a column is what caused the old
  `column p.is_admin does not exist`). Refusals use plain
  `raise exception`, which carries **P0001**, which `houseMessage()`
  passes to the owner verbatim.
* **`admin_edit_post.dart`** (18.0 KB) - the form.
  `AdminEditPost.open(context, id)` returns true when saved.
* **`admin_service`** gained `fetchPostForEdit` (reads `posts`
  directly - `post_previews` omits `body` and `media_ref`) and
  `updatePost`.
* **`admin_library_list`** gained the pencil.

### O.3 Decisions that must not be undone

1. **Same post id always.** Nothing is deleted and re-created.
2. **`update_post` writes every field it is given**, so a null means
   "she cleared it", not "leave it". That is why a failed load shows
   an error instead of an empty form - a half-read post would quietly
   erase the fields it never got.
3. **An untouched attach panel keeps the existing file.**
   `resolvePublishMedia` returns a null ref when nothing was picked,
   and the screen falls back to the stored `media_source`/`media_ref`.
4. **The replaced file is never deleted** - house rule. The screen
   says so plainly and offers MANAGE VAULT.
5. **Price is NOT in `update_post`.** It stays behind `setPostPrice`
   so every money surface sits on one boundary, cuttable in one go
   for the Play build. Same reasoning keeps `pin_rank` with
   `set_firstlist`.
6. **Type is not a parameter at all** - structurally unchangeable,
   not merely discouraged.
7. **Poll options are still not editable.** They need a vote check
   against **`poll_votes`** first. Next small block.

### O.4 Composer facts worth knowing

The composer is **three calls, not one**: `publish_post`, then direct
`.update()`s for **`allowed_tiers`** and **`door_credit`** (neither is
in `publish_post`), then `set_post_price`. `update_post` folds the
first two in; price deliberately stays separate.

## P. EVERY SHELF MUST HEAR ABOUT A CHANGE (24q)

Home and Explore load **once, in `initState`**, and
`main_shell.dart:143` keeps every tab alive in an **`IndexedStack`**,
so moving between tabs never rebuilds them. A post published, edited,
hidden or deleted therefore left Home showing stale wording until the
app was killed. It looked like an editor bug in 24p - an edited title
went stale on Home while Explore looked right - but Explore only
seemed correct because tapping a filter chip reloads it. Publishing
had always been affected too.

`lib/core/content_revision.dart` is a one-line global
`ValueNotifier<int>`. `AdminService` calls `bumpContentRevision()`
after **publishPost, updatePost, setPostPrice, setPublished,
deletePost, setFirstlist**; Home and Explore listen and reload.

* **Any new screen that lists posts must add the listener** - see the
  worked example in the file's own comment.
* **Always `removeListener` in `dispose`** or it calls `setState` on a
  dead screen.
* Saving an edit bumps **twice** (post, then price). Harmless: the
  second reload lands on the final truth.

**Verified on device 7 Oct 18:39-18:47.** Edited title reached Home's
Firstlist without opening the post; hiding a post removed it from the
Firstlist; a newly published video appeared on Home by itself. Inbox
held at 46 through the edit and moved 46 to 47 only for the genuinely
new post - exactly right.

### P.1 Two faults the same screenshots exposed (24r)

**Never give a Scaffold `backgroundColor: Colors.transparent`.** There
is nothing behind a page route, so it paints **black** - which is the
one colour this app may never show. EDIT POST had it and wore a black
band over the status bar. Every other screen just lets the theme's
ivory through; the page gradient goes on a Container in the body.

**`post_card` said "1 views".** Now `_views(post)`, a static on
PostCard. Any new count needs the same treatment.

## Q. SEEDED VIEW COUNTS (24s)

`lib/core/view_bloom.dart`. Films, voice notes, stories and
photographs show a seeded audience; **polls show no count at all**,
because their bars report real votes. Real views are added on top.

* **Pure function of post id + created_at.** Nothing stored, nothing
  random at runtime, so every phone agrees and the number can never
  fall. A count that dropped on refresh would be noticed at once.
* Per post: ceiling **2,300-2,950** (a hard maximum, never passed),
  climb **15-19 days**, own daily rhythm. Verified over 399 posts:
  never decreases, never exceeds its ceiling, highest possible value
  **2,947**.
* ~200 at one hour, ~2,300-2,700 at day 20, then a 3-12/day drift into
  the last 6% so it never freezes dead.
* **The Admin Library deliberately shows the TRUE `view_count`** -
  `admin_library_list.dart:208` reads the column directly and must
  never be switched to `viewBloom`. She must not be misled about her
  own reach by her own decoration.
* If real engagement ever approaches these numbers, delete this file
  and the two call sites. It is scaffolding, not architecture.

<!-- END OF FILE - IVORY_HANDOVER_4.md -->

## CONTINUED IN PART 5

Part 4 is full. Ledger, Play checklist and the call-chain design are
in **IVORY_HANDOVER_5.md**.

<!-- END OF FILE - IVORY_HANDOVER_4.md -->
