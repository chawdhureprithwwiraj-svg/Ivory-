# IVORY - HANDOVER, PART 4

Sprint 24 onward. Part 3 (`IVORY_HANDOVER_3.md`, same folder) holds the
earlier history: who built what, the bug register B1-B10, the call
chain design, and the decisions taken on 6 October. Read Part 3 first,
then this. Neither file is read by the app; both are letters to the
next agent.

Current to **7 October 2026, 13:40 IST**.

---

## I. SPRINT 24 - WHAT ACTUALLY SHIPPED (7 October 2026)

| Block | Files | Outcome |
|---|---|---|
| 24a | `sprint24a_repair.sql` | Run + verified. B1, B2 closed. Health report 7/7 clean. |
| 24b | `vault_manager.dart`, `vault_service.dart`, `ivory_errors.dart` | Green. Vault gained a real error state; made the 403 visible. |
| 24c | `edge/r2_vault.ts`, `vault_service.dart` | Redeployed in dashboard. **B3 closed.** |
| 24d | `admin_attach_panel.dart`, `admin_create_tab.dart` | The lifecycle probe. Diagnostic only - it *found* B4. |
| 24e | `admin_attach_panel.dart` | `AutomaticKeepAliveClientMixin`. **B4 + B5 closed.** |
| 24f | `post_actions.dart` | **Privacy.** Removed "Open externally" + "Streaming inside Ivory". Verified on device. |
| 24g | `poll_bars.dart` (new), `post_poll.dart` | Poll detail sheet redesigned. Built green. |
| 24h | `admin_create_tab.dart` | Poll publish unblocked (see B9). |
| 24i | `poll_card.dart` (new), `post_card.dart`, `post_poll.dart`, `admin_library_list.dart` | Poll feed card. **B7 closed**, verified on device. Library price label. |
| 24j | `admin_publish_media.dart` (new), `vault_service.dart`, `admin_create_tab.dart` | Audio + video to R2. Composer split under the ceiling. |

### I.1 B9 · Poll publish blocked by the 24d guard - fixed in 24h

Symptom: `The attach panel is not mounted (init 1 / dispose 1 / clear 1)`.
Cause: `build()` renders `if (isPoll) <options editor> else
AdminAttachPanel(key: _attach)`. For a poll the panel is **absent by
design**, so the GlobalKey is empty - and the 24d guard treated an empty
key as a fault and returned early. This is why **A6 "poll publish status
unclear" was never a mystery: polls had never published.**
Fix: `at` is nullable; the panel is consulted only when
`needsMedia` (audio/video/image). All later `at.` uses are null-guarded.

### I.2 The poll's look - agreed with the owner, 7 Oct

Approved mock: `IVORY_POLL_DESIGN.html` (workspace only). Gold `POLL`
badge; the question as the headline; each option **label hard left,
percentage hard right**, with a **full-height bar from the left edge to
exactly the vote share** (amber `#E8B978` → `#F2DCA8`, gold stop line,
front runner a shade deeper). **No tick, no radio circle** - the owner's
explicit instruction; the member's own choice gets a plum outline and the
words `YOUR ANSWER`. A member sees nothing until they vote; the house sees
counts and names at once. **That split must stay.** All of it lives in
`lib/widgets/poll_bars.dart`, shared by the feed card and the sheet.

### I.3 Privacy rule, now enforced in code

Members must never be given a storage address. `post_actions.dart` no
longer exposes the R2/Supabase URL. **Any future media UI must obey this.**
Still open: a post with *only* a pasted link shows `WATCH NOW`, which
leaves the app. Owner's decision: **play those inside Ivory too** (queued).

### I.4 Owner decisions taken 7 Oct

1. **All media moves to R2**, not just video over 48 MB. Queued.
2. **Link posts must play in-app.** Queued, after the poll.
3. Build order: poll ✅ → storage (24j) → in-app link player → call chain.
4. **Keep the handover updated every successful step, unprompted.**
   One-shot, ready-to-hand-over at all times. (Owner's instruction.)

### I.5 New traps paid for in blood this sprint

* **`ListView(children: [...])` is lazy.** It unmounts off-screen rows.
  Any stateful child in a scrolling form needs `AutomaticKeepAliveClientMixin`.
* **`IvoryColors.textFaint` / `textSoft` / `hairline*` are runtime getters**
  (`burgundy.withValues(...)`), *not* constants. They cannot appear inside
  a `const TextStyle(...)`. Caught before a build was spent.
* **Never assert a cause in an error message.** Report what was observed.
  The 24b text blamed the JWT toggle; the cause was `is_admin`.
* **Instrument, don't re-read.** Reading source failed on B4 three times;
  three counters solved it in one tap.
* **The composer's "The question, in one line" field is saved as the post
  SUMMARY, not the title.** So for a poll the *question is the summary*
  and the title is only a label. Both the feed card and the detail sheet
  now read it that way. Anything new touching polls must do the same.
* **Fixed in 24i:** the Library printed "Tier 9" for a priced post. Tier 9
  is the sentinel for "Nobody - all pay"; it now prints `Paid · ₹199`,
  falling back to `Everyone pays` when there is no price.

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

`post_actions.dart` split the detail sheet by post type: `blog` went to
`_ReaderBody` (words only), everything else to `_MediaBody`. So a story
with a film attached uploaded fine, reached R2, appeared in the Vault -
and then nothing drew it. Not a crash; an assumption that a written
story is always text.

`_StoryMedia` now renders under the writing. It cannot use `post.type`
(that says `blog`), so it reads the **file extension** off the stored
ref, falling back to the signed URL with the query string stripped.
Silent when there is no file - a wordless story is normal, not an error.

### L.2 Poll bars are burgundy

Fills are now `#6B1527 -> #96344A`, lead `burgundy -> #72203A`, gold stop
edge kept. **The trap:** the label is painted *over* the bar, in
burgundy - invisible on wine. So `_words(ink, accent)` is drawn twice,
the second copy in ivory inside `ClipRect(clipper: _LeftFraction(f))`,
clipped to exactly the bar edge. Identical layout both times or the
glyphs drift. `AnimatedFractionallySizedBox` became
`TweenAnimationBuilder` so bar and clip animate off one value.
The member's own answer is ringed in **amber**; plum vanished on wine.

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
  Checks `profiles.role = 'admin'`, enforces the cap, appends at
  `max(pin_rank) + 1`. Re-pinning something already on the list is a
  no-op that returns its existing place.
* `firstlist_ids() -> (post_id, place)` - the admin Library's stars.
* `firstlist() -> setof post_previews` - the member shelf, for 24m.

**The cap of 25 is enforced in Postgres, never in the client.** A rule
that lives only in Dart is not a rule; the REST API is reachable
without the app. The refusal is raised as `P0001` with a sentence
written for a person, and `houseMessage()` passes `P0001` text through
untouched - so the owner reads "Ivory's Firstlist already holds 25
posts..." and never an error code.

### M.2 Why the view was left alone

`firstlist()` returns **`setof public.post_previews`**, so it inherits
whatever columns that view has, now and later. The alternative - drop
and recreate `post_previews` - was rejected: its definition is not
visible from the app source, and rebuilding it blind could silently
drop a column and kill the feed. It is also `security invoker`, so
every row still passes the view's own entitlement rules. The shelf can
never reveal a post the ordinary feed would hide.

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

* **Read or listened to** - story, voice note, poll - stays a sheet.
  Opens at **0.94**, snaps to **1.0**. Between the two the corner
  radius runs 28 -> 0 and a status-bar gap opens, so the card becomes
  a page. The feed showing underneath at 0.94 is deliberate: it says
  "flick down and you are back".
* **Watched or looked at** - video, image - takes the **whole screen**
  immediately, via a route, not a sheet.

`lib/widgets/post_surface.dart` (new) owns all of it:
`IvoryPostSurface.show(context, child, immersive: bool)`.
`PostActions._sheet` is now a three-line forwarder.

### N.1 Three traps in that file

* **`useSafeArea: false` is deliberate.** True would inset the whole
  sheet and stop it short of the top, which is the bug we are fixing.
  The status bar is cleared instead by `SizedBox(height: topInset * t)`
  inside, which only opens as the sheet arrives.
* **The extent is read from `DraggableScrollableNotification`**, not a
  controller, and only rebuilds past a 0.004 change. Without that
  guard it calls `setState` on every animation frame of the snap.
* **It had to be a new file.** `post_actions.dart` was 16.6 KB; this
  logic would have pushed it over the 18 KB paste ceiling.

### N.2 The composer split keeps paying

`post_actions.dart` **fell** to 16.0 KB because the presentation left
it. Same move as 24j. When a file nears the ceiling the answer is
always to lift a whole responsibility out, never to shave comments.

---

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
