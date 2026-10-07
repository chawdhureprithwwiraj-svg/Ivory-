# IVORY - TECHNICAL HANDOVER, PART 3

## THE LIVE LEDGER - SPRINTS, BUGS, AND WHAT HAPPENS NEXT

*Parts 1 and 2 (`IVORY_HANDOVER.md`, `IVORY_HANDOVER_2.md`) describe what
Ivory is and how it is built; they change rarely. **This file changes every
sprint.** It supersedes §10 and §12 of Part 2.*

**Last updated: 7 October 2026 (00:40 IST)** · Repo state: **Sprint 23 installed
and building** · **24a RUN AND VERIFIED GREEN** · 24b built green · **24c delivered:
the 403 is root-caused**

---

## A. WHO BUILT WHAT

Agent #1 took Ivory to sprint 13. Agent #2 took it to sprint 23 and froze
mid-sprint-24. Agent #3 (this one) took over on 6 Oct 2026 and completed
sprint 24 blocks a–j. Parts 1 and 4 of sprint 24 are done; parts 2 and 3
(the call chain) are not started.

## B. SPRINT LEDGER 13 → 24

| # | Name | What it added | SQL | State |
|---|---|---|---|---|
| 13 | Clean copy | Payment/store-safe rewrites of hero, sign-in, Wish strip, Premium line | `sprint13_clean_copy.sql` | ✅ installed |
| 14 | The Vault | Private media vault backing R2 | `sprint14_vault.sql` | ✅ installed |
| 15 | Officer + Razorpay | Grievance-officer identity; Razorpay as a parallel rail to UPI | `sprint15_officer.sql`, `sprint15_razorpay.sql` | ✅ installed |
| 16 | Gift ladder | Gift catalogue and payment rails | `sprint16_gifts.sql` | ✅ installed |
| 17 | Story door | The story-door backend, `posts.door_credit` | `sprint17_door.sql` | ✅ installed |
| 18 | Fixes | Call fix + live-pass (pay-per-view seat) rail | `sprint18_fixes.sql` | ✅ installed |
| 19 | Audience | Full audience control - `posts.allowed_tiers integer[]`, pick any mix of tiers | `sprint19_audience.sql` | ✅ installed |
| 20 | Calls | One session at a time, fair cycles | `sprint20_calls.sql` | ✅ installed |
| 21 | Calls polish | Join windows, member names, reminder cron `ivory-call-reminders`. **Fixed `p.is_admin` → `p.role` in `request_call`.** | `sprint21_calls_polish.sql` | ✅ installed |
| 22 | Gifts/polls/extensions | Gift sender names, poll voters, call extensions, cal.com booking. **Reintroduced the `p.is_admin` bug in `confirm_my_booking`.** | `sprint22_gifts_polls_extensions.sql` | ✅ installed |
| 23 | R2 Vault in-app | `r2-vault` edge function, 9 GB cap, no auto-delete, vault manager, attach panel, path-only pick for big video | - | ✅ built, **buggy at runtime** |

**Sprint 23 build log is clean:** `✓ Built app-release.apk (258.5MB)`, no
errors. Every sprint-23 problem is a **runtime** fault, not a build fault.
Do not go looking for Gradle or SDK causes.

---

Sprint 24 is broken out block-by-block in section I.

## C. BUG REGISTER - SPRINT 23

Found by reading the actual source, not by guessing. Status is honest.

### ✅ B1 · `column p.is_admin does not exist (42703)` - CLOSED (24a + 24c)

There is **no `is_admin` column**; admin is `profiles.role = 'admin'`.
Wrong in **three** places across three sprints: sprint20 SQL, sprint22 SQL
(`confirm_my_booking`), and `edge/r2_vault.ts`. An audit of every other
edge function is clean (`agora-token` correctly calls the `is_admin()`
*function*; the `rzp_*` and `send-push` functions do no admin lookup).

### ✅ B2 · `This session is not ready to be booked yet. (P0001)` - CLOSED (24a)

The gate tested `status = 'accepted'` while `activate_payment` wrote
`'confirmed'`.

### ✅ B3 · MANAGE VAULT spins forever - **CLOSED 7 Oct (24b + 24c)**

Two bugs stacked. (1) `vault_manager.dart` `_load()` had no try/catch and
`items()` returned `[]` on failure, so a broken Vault looked like an empty
one - fixed in 24b. (2) The real failure: `edge/r2_vault.ts` gated every
house operation on `profiles.is_admin`, **a column that does not exist**.
Every `list`/`usage`/`put`/`delete` had answered 403 since sprint 23.
Fixed to `profiles.role = 'admin'`, redeployed from the Supabase dashboard
(no APK needed). Vault now reports `0.1 GB of 9.0 GB used` and lists items.

### ✅ B4 · Video publish fails, file chip vanishes - **CLOSED 7 Oct (24e)**

Not the edge function - it survived the 24c fix. The 24d probe returned
`init 2 / dispose 1 / clear 3`: the attach panel had been **destroyed and
rebuilt**. Cause: **a `ListView(children: [...])` is still lazy** and
unmounts rows scrolled off screen. Attaching at the top then scrolling to
PUBLISH NOW killed the panel. The Title survived because it lives on the
parent, which never scrolls - that asymmetry misled three rounds.
Fix: `AutomaticKeepAliveClientMixin` + `wantKeepAlive` + `super.build()`.
**Previously recorded as "eliminated" on the false belief that an
explicit-children ListView is eager. It is not.**

### ✅ B5 · Priced posts fail - **CLOSED 7 Oct (24e), same bug as B4**

Never a database fault. Every DB cause had already been eliminated
(columns, `set_post_price` signature, admin row). The ₹199 image failed
because its file vanished with the panel. A ₹199 image published cleanly
on the 24e build. **B4 and B5 were one bug wearing two coats.**

### 🟠 B6 · Raw `PostgresException` text shown to members - fix in 24b
`admin_create_tab.dart:235` does `_toast('Could not publish: $e')`, and the
call sheet renders `P0001` / `42703` verbatim. Breaks the house rule that a
member never sees internals. Needs a global catch-and-map helper.

### ✅ B7 · Polls look like post cards - **CLOSED 7 Oct (24g + 24i)**
`post_poll.dart` + the home-feed card render a poll through the generic post
cover, so it reads as "Please send" with a vote attached. Wanted: a
YouTube/Facebook-style poll - POLL chip, bold question, tappable options,
percentage bars and total votes after voting, no cover art.

### 🟡 B8 · cal.com leaks the owner's email - resolved by removal in 24d
cal.com's confirmation screen shows the host's address. **Decision (owner,
6 Oct): cal.com leaves the booking loop entirely** - which also kills the
browser-chooser popup, the "Picked a slot?" dialog and the TELL IVORY dead
end.

---

## D. THE CALL CHAIN - AGREED DESIGN (Sprint 24d)

Owner-specified, confirmed 6 Oct 2026. Replaces the cal.com flow.

```
member picks VIDEO or AUDIO   (wish-payer path OR premium-minutes path)
      ↓
admin APPROVES the request
      ↓
member PROPOSES date + time    ← in-app picker. No cal.com. No browser.
      ↓
admin sees it → APPROVE   or   REQUEST CHANGE (+ a short note)
      ↓                               ↓
      │                     member re-proposes → back to admin
      ↓
admin FINAL-APPROVES → member gets the final confirmation
      ↓
reminders to BOTH sides: 2 days · 1 day · 6h · 1h · 30m · 10m
      ↓
JOIN activates at T−5 min; whoever arrives first waits for the other
      ↓
both connected → countdown starts
      ↓
wish member  → extension offer at admin-set price, admin-set duration 30–120 min
premium member → minutes auto-deducted from balance, remainder shown
```

### D.1 Scheduling rules - enforced in Postgres, never in the client
- **Minimum 4 hours' notice.** No slot may start sooner than `now() + 4h`.
- **No session may start between 03:00 and 12:00 IST.**
  Bookable window is therefore **12:00 noon → 03:00 the next morning**, IST.
- All times stored as `timestamptz`, compared in `Asia/Kolkata`.

Put these in the database so a tampered APK cannot bypass them (Part 1 §3:
*the client never decides anything*).

### D.2 Call minutes must stay data-driven
The owner has **not finalised the tiers yet** and expects to change her mind.
Video will probably sit in the top one or two tiers, audio in the 3rd or 4th
— but nothing is settled.

**Therefore: never hardcode a tier number or a minute count anywhere.**
Add `video_minutes` and `audio_minutes` columns to the tiers table,
defaulting to `0`. A tier offering `0` simply does not offer that call type.
When the owner later fills the numbers in via Admin → TIERS, the behaviour
changes instantly with no code change and no rebuild.

---

## E.3 NEW TRAP - THE HEALTH REPORT HAS A BLIND SPOT

24a's check A scanned `pg_proc` and truthfully reported **none** - right
about Postgres, blind to everything else: **edge functions are TypeScript
on Deno, not rows in `pg_proc`.** The same `is_admin` mistake sat in
`edge/r2_vault.ts` the whole time, invisible to the probe.

*Rule: when hunting schema drift, grep the edge functions and the Dart as
well as the database. `is_admin` has been wrong in three places across
three sprints (sprint 20 SQL, sprint 22 SQL, sprint 23 edge). Assume a
fourth until you have grepped for it.*

---

## F. DECISIONS TAKEN (6 October 2026)

| Question | Answer |
|---|---|
| cal.com in the booking loop | **Removed.** In-app picker instead. |
| Booking notice | **4 hours minimum.** |
| Booking hours | **Nothing starting 03:00–12:00 IST.** |
| Tier call minutes | **Deferred by the owner.** Build data-driven, default 0. |
| GitHub token for the agent | **Declined.** Copy-paste keeps the owner's review step, and the agent cannot build the APK anyway. |
| Build/compile in the agent's sandbox | **Forbidden.** Source output only. |
| Handover format | **Three parts**, each under the 18 KB ceiling, Part 3 updated every sprint. |

---

## G. STILL BLOCKING LAUNCH (carried from Part 2 §10)

1. **Set a real UPI id** - Admin → PAYMENTS. Until then nobody can pay.
2. **Publish the Grievance Officer** - Admin → REPORTS. Safe harbour depends on it.
3. **Finalise tier prices and call allowances** - Admin → TIERS.
4. **Write the four policy pages** - Terms, Privacy, Refunds, Content.

---

---

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
exactly the vote share** (amber `#E8B978` -> `#F2DCA8`, gold stop line,
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
3. Build order: poll ✅ -> storage (24j) -> in-app link player -> call chain.
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

---

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

*(Moved down from Part 4 on 7 Oct - 24l and 24m are
shipped and verified, so this is history now.)*

## CONTINUED IN PART 4

Everything from Sprint 24j onward - storage, the Firstlist, how a post
opens, and the editor design - lives in **`IVORY_HANDOVER_4.md`**, in
the repo root beside this file. Part 3 is the history and does not
change again.

<!-- END OF FILE - IVORY_HANDOVER_3.md -->
