# IVORY - HANDOVER, PART 5

Current to **7 October 2026, 20:10 IST**. Parts 1-4 still apply and
are not repeated here. Part 4 reached its size ceiling at §Q.

Read in this order: Part 3 (§A-§I, history), Part 4 (§J-§Q, the
content system), then this.

---

## R. WHERE THE BUILD ACTUALLY STANDS

### R.1 On the device, built and verified

| Sprint | What | State |
| --- | --- | --- |
| 24a-24i | Admin create defects A1-A6, poll redesign | closed |
| 24j.1, 24k | storage map, vault | closed |
| 24l, 24m | Ivory's Firstlist | closed, verified |
| 24n, 24o | adaptive post surface, story layout | closed |
| **24p** | **editing a post** | **built + verified on device** |
| 24p.1 | the missing `dart:ui` import | in |
| **24q** | **feeds refresh themselves** | **built + verified** |
| 24r | EDIT POST black band, "1 view" | in |
| **24s** | **seeded view counts** | **built + verified** |
| 24t | "1 view" in the Library, "1,771st" | delivered, not yet built |
| **25a** | **call-chain inspection SQL** | **delivered, result awaited** |

### R.2 The only feature never started

**The call chain.** Everything else she asked for across Sprint 24 is
done. See §T.

### R.3 Known, accepted, not bugs

* Black rectangles inside video posts are **baked into her own
  clips** (letterbox bars on one export, a black first frame on
  another). `ivory_media_view.dart` already paints `surfaceWarm`
  behind the player. No code fixes this - only re-exporting does.
* `admin_edit_post.dart` is **562 lines**, over the ~500-line rule,
  under the byte ceiling. Lift the two notice cards into a shared
  file when the poll-options block lands.
* `post_actions.dart` is **16.9 KB / 504 lines, at the ceiling.** The
  next change there must extract `_ReaderBody` + `_StoryMedia` into
  `post_reader.dart` first.
* `tools/dart_check.py` has two proven blind spots: it cannot tell
  whether a **type name is supplied by an import** (let `FlutterView`
  through, cost a four-minute build), and it will **pass a file
  broken mid-edit** (a comment inserted between `static` and its
  declaration). Both are committed follow-ups. Until then: grep every
  non-material type and every service method name by hand before
  delivering.

---

## S. THE SEEDED NUMBERS AND THE LAW

This section exists because the owner asked, directly, whether the
seeded view counts and the member pulse would survive app-store
registration. The honest answer has two halves that point in opposite
directions, and the second half is the one that matters.

### S.1 App stores - low risk

Google Play's **Deceptive Behavior** policy is about metadata,
impersonation, impossible features and hidden code. A seeded view
counter is none of those, and **no reviewer, human or automated, can
tell 1,324 from a real 1,324.** The same is true of the Samsung
Galaxy Store, Amazon Appstore, Xiaomi GetApps, Huawei AppGallery, the
Indus Appstore, and any sideload channel - all of which review more
lightly than Play. **Expect these to pass.**

Play's real blockers for Ivory are elsewhere and already known:
Play Billing for digital goods, and the 18+ content rating.

### S.2 Indian law - this is the actual exposure

The **Guidelines for Prevention and Regulation of Dark Patterns,
2023**, issued by the CCPA under s.18 of the Consumer Protection Act
2019, are **mandatory** and took effect 30 November 2023. They apply
to "all platforms systematically offering goods or services in
India". Ivory sells digital content in India, so they apply.

Dark pattern number one on the list is **False Urgency**, and the
government's own illustration of it is:

> *"Falsely showing high **popularity** of a product"* - for example
> *"Only 2 rooms left! 30 others are looking at this right now."*

**"You are the 1,771st member who visited today"** is close to a
textbook match for the second half of that illustration. A seeded
view count next to a paid post is close to the first half.

* Penalty, s.89 CPA: first contravention up to **two years and
  Rs 10 lakh**; repeat up to five years and Rs 50 lakh.
* Enforcement is real, not theoretical: CCPA has acted against
  BookMyShow, MakeMyTrip, IndiGo and Flipkart, and fined SpiceJet
  Rs 1 lakh **specifically for false urgency**.
* **Any single member can file** through the Jagriti app by entering
  the URL or app; it is treated as a formal CCPA complaint.

*(I am not a lawyer and this is not legal advice. It is what the
published guidelines say.)*

### S.3 The distinction that decides everything

The guideline targets a fake popularity signal **that pushes a
purchase**. That gives a clean, defensible line:

* A seeded count on a **free** post is decoration. Nobody is
  transacting. The legal theory has nothing to attach to.
* A seeded count on a **locked or priced** post is social proof
  standing directly beside a payment button. That is the mechanism
  the guideline describes.

### S.4 The recommended shape - "Ivory clean"

1. **Suppress the seeded count on any post that is locked or
   priced.** Free posts keep it; paid posts show the real count or
   nothing. Small change in `post_card.dart`, and it removes the
   popularity-to-purchase link entirely.
2. **Retire or make truthful the member pulse's "visited today"
   line.** It is the single riskiest surface in the app, because it
   claims live human presence. Either make it a real count or drop
   the "today" framing.
3. **Put both behind one constant**, exactly as the money surfaces
   are - `const bool kSeededCounts = true;` in one file, so a store
   build strips all of it in a single edit. This is the same
   discipline already agreed for UPI/Razorpay.
4. Never state a seeded number **anywhere outside the app** - not in
   the store listing, not in screenshots, not in marketing. That
   crosses from app design into misleading advertising, which is a
   separate and better-established offence.

### S.5 DECISION 7 Oct - NOT built, deliberately

**The owner has ruled: the sideloaded APK stays exactly as it is.**
It is not going to Google Play, it is not a public store listing, and
she does not want it sanitised. Every seeded number stays everywhere,
including on paid posts.

The Play build will be a **separate, polished edition** in which the
payment surfaces are stripped. **All of §S.4 is to be applied there,
in one pass.** This section is that checklist - do not act on it
before then.

Sprint 24u (`house_numbers.dart` + a guarded `view_bloom.dart`) was
written and then **shelved unbuilt** on this instruction. It does not
exist in the tree. Re-create it at Play time; the design is §S.4 and
the reasoning is §S.2.

**THE PLAY-BUILD CHECKLIST - one pass, nothing forgotten**

1. Strip UPI / Razorpay / every in-app payment path. Play Billing or
   the consumption-only model (see Part 4).
2. Seeded view counts off on anything priced or tier-locked - or off
   entirely.
3. The member pulse line removed or made truthful. **This is the
   riskiest single surface**; it claims live human presence, which is
   the government's own illustration of false urgency.
4. No seeded number anywhere in the store listing, screenshots or
   marketing copy. That is misleading advertising, a separate and
   better-established offence than dark patterns.
5. 18+ content rating declared correctly.
6. Grievance Officer, Terms, Privacy, Refunds, Content policy live.

### S.6 Superseded - what 24u would have contained

`lib/core/house_numbers.dart` holds two constants and the reasoning:

* `kSeededNumbers` - the master switch. False strips every invented
  number from the app in one edit. **Set it false for the Play
  build.**
* `kHideSeededOnPaid` - true. A post that `isForSale` or `isPremium`
  falls back to its real view count, or shows nothing.

Points 1 and 3 of §S.4 are **done**. Point 4 is a standing rule, not
code. **Point 2 - the member pulse - is deliberately NOT changed.**
She likes it and it had just been fixed to read "1,836th". It is the
riskiest surface in the app because it claims live human presence,
and it is governed by `kSeededNumbers`, so it disappears with
everything else when the switch goes off. **Revisit before any Play
submission.**

---

## T. THE CALL CHAIN - THE LAST FEATURE

### T.1 What is broken today (her defect list)

* **M1** raw Postgres text reaching members: *"This session is not
  ready to be booked yet. (P0001)"*, *"column p.is_admin does not
  exist (42703)"*.
* **M2** a browser chooser appears mid-flow.
* **M3** TELL IVORY produces nothing.
* **M4** the chosen slot is invisible to both sides.
* **M5** cal.com exposes her personal email.

**cal.com removal is approved.** Booking moves in-app.

### T.2 The flow, agreed

member picks video or audio call (wish path, or premium-minutes path)
-> admin approves -> member schedules -> admin **APPROVE** or
**REQUEST CHANGE** -> member re-proposes -> admin final-approves ->
member confirmation -> reminders to **both** sides at 2d / 1d / 6h /
1h / 30m / 10m -> JOIN activates at **T-5 min** -> countdown starts
only when **both** have connected -> extension prompt near the end.

### T.3 Scheduling rules, fixed

* Minimum **4-hour** buffer from now.
* **No slots 03:00-12:00 IST.** Bookable window is 12:00 -> 03:00
  IST.
* Tier allowances and call minutes stay **data-driven**. No
  hardcoded tier numbers or minute values, ever.

### T.4 Running out of minutes mid-call - DECIDED 7 Oct

The owner's instruction: **mirror the wish-path extension for premium
members.** She wants a price box and a duration box she can edit,
the same way the wish path already works.

So: **the call does not cut off, and nothing is auto-billed.** Near
the end of the paid block both sides see an extension prompt. The
member accepts and pays for one more block. If they decline, the call
ends at the boundary.

* `payment_settings.ext_block_minutes` - clamp **30-120**.
* `payment_settings.ext_price_inr`.
* Both edited by her in Admin, one screen, alongside the wish dials.
* **Improvement to offer her:** a separate pair of dials for the
  premium path versus the wish path, since a premium member has
  already paid once and a flat rate for both will be wrong for one of
  them. Also a hard cap on extensions per call, so a long call cannot
  run away.

### T.5 Schema

`call_requests` state machine:
`requested -> confirmed -> scheduled/proposed -> reschedule -> final
-> done/cancelled`, plus `proposed_at`, `proposed_by`, `admin_note`.
New `member_minute_ledger`. `payment_settings` gains the two
extension columns above.

**Nothing may be written until `sprint25a_call_inspect.sql` comes
back.** The last time schema was assumed in this area it produced
`column p.is_admin does not exist` - `is_admin` is a **function**,
not a column.

### T.6 Agent #2's unfinished `live_service.dart` patch

Still to land, verbatim from the design:

* `slotDecision(int callId, {required bool approve, String? note})`
  -> `admin_slot_decision`
* `myMinutes()` -> `my_minutes`
* `saveExtDials(int minutes, int priceInr)` -> `payment_settings`
  where `id = 1`

### T.7 Build order - one build each

1. **25b** the database: state machine, ledger, extension dials.
2. **25c** `call_sheet_member.dart` - request, schedule, re-propose,
   confirm.
3. **25d** `call_sheet_admin.dart` - approve, request change, final.
4. **25e** reminders + the T-5 join window, reusing the existing
   `ivory-call-reminders` cron.

`call_book_flow.dart` is **replaced** by the two sheets, not patched.

---

## U. WHERE THE CALL CHAIN ACTUALLY IS

### U.0 THE BIG FINDING - 25b, 7 Oct 20:32

**The call chain is not missing. It is built, and broken.** 25b's
report returned **fourteen existing functions**:

`request_call` · `respond_call` · **`set_call_time` (TWO
overloads)** · `join_call` · `end_call` · `call_window` ·
`call_balance` · `list_calls` · `adjust_call_usage` ·
`submit_call_extension_payment` · `remind_calls` ·
`sweep_missed_calls` · `mark_call_missed`

And `call_requests` already carried: `channel_name`, `charged`,
`minutes`, `price_inr`, `payment_id`, `note`, `requested_for`,
`window_end`, `reminded_at`, `missed_at`, `joined_host`,
`joined_member`, `extension_paid`, `extension_price`,
`extension_payment_id`.

**This rewrites the plan.** §T described building a call chain from
nothing. The real job is a **repair** of a working engine. Do not
write `book_slot` or `admin_slot_decision` from scratch before
reading what `set_call_time` and `respond_call` already do.

**`set_call_time` exists TWICE.** Two overloads of the same name is
trap 11.8 and is the prime suspect for **M4, the chosen slot being
invisible on both sides** - the app may be calling one signature
while the other holds the logic. Resolve this before anything else.

Statuses actually in the table: `accepted`, `active`, `completed`,
`declined`.

### U.1 A mistake in 25b, corrected in 25c

The 25b status list **omitted `declined`**, which is in live use.
`NOT VALID` meant nothing broke, but a new declined row would have
been refused. 25c rewrites the constraint with `declined`, `missed`
and `expired` added.

### U.2 What 25b did land

* All eleven scheduling columns on `call_requests`.
* `member_minute_ledger`, with RLS so a member sees only their own.
* Five dial columns on `payment_settings`, the 30-120 clamp in the
  database, and one settings row - `id=1`, UPI **set**, dials at
  `wish 30min/Rs0  premium 30min/Rs0  cap 2`.

**She must set the two prices in Admin - they are Rs 0 today.**

### U.5 - U.7 HAVE MOVED

Part 5 reached its 18 KB ceiling here. The fourteen verified call
signatures, the M4 root cause and the facts read out of the
function source now live in **IVORY_HANDOVER_6.md**. Read Part 6
before touching the call chain.

### U.3 Next actions

1. Run `sprint25c_call_functions.sql`. Fixes the status list, then
   reports the signatures of all fourteen functions.
2. Read `set_call_time`'s two overloads. Drop the dead one
   (`drop function if exists ...(args);` - trap 11.8).
3. Only then write the repairs, and the scheduling guard: 4-hour
   buffer, 12:00-03:00 IST window.
4. `call_sheet_member.dart` / `call_sheet_admin.dart` last.

### U.4 A workspace warning for whoever is next

This tree has **silently rolled back twice**, losing newly created
files under `lib/core/` and reverting shell-edited files. The owner's
GitHub is the only reliable record. **Before delivering any file,
re-read it and check its byte length.** Never assume an edit from an
earlier turn survived.

---

## V. STANDING RULES THAT KEEP BEING RE-LEARNED

* **Never assume a method name.** `fetchTiers` does not exist; it is
  `fetchAllTiers`. Grep first.
* **Match the codebase, not the newer API.** It is `activeColor`,
  not `activeThumbColor`.
* **Never give a Scaffold `backgroundColor: Colors.transparent`** -
  there is nothing behind a page route, so it paints black.
* **`IndexedStack` keeps every tab's State alive.** A screen that
  loads only in `initState` shows stale data forever. See §P.
* **Measure files in UTF-8 bytes**, not characters. `-` and `.` are
  cheap; em-dashes and middots cost 3 bytes each.
* **Near the ceiling, lift out a whole responsibility.** Never shave
  comments.
* **SQL goes into the chat as a code block**, never only as a file -
  she cannot copy out of the workspace preview.
* **No line of pasted SQL may end with an open bracket** - the
  Supabase mobile editor auto-closes it and produces `42601`.
* **There is no git in the working tree.** Verify byte length before
  any destructive edit. Local edits have silently rolled back once -
  re-verify before assuming a change is still there.

<!-- END OF FILE - IVORY_HANDOVER_5.md -->
