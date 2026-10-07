# IVORY - HANDOVER PART 7

Continues IVORY_HANDOVER_6.md. Parts 3 to 6 still stand.

This part begins at the first live end-to-end call test, run by
the owner on two handsets on 7 Oct 2026, and covers the work that
test triggered.

## V. THE 7 OCT LIVE CALL TEST - what it proved

Member account `yourpritz24` (Protz) and the admin account, run
side by side at 22:17-22:27.

### V.1 M4 IS CONFIRMED FIXED ON DEVICE

Admin CALLS tab showed **"Agreed for 8 Oct, 2:30 am"** on a
confirmed request. A chosen slot is stored and displayed for the
first time. 25e closed it.

Also confirmed working on device:
* Prices flow from `wish_categories` - Wish screen shows
  "Rs 2999 onwards, 30 minutes of video" and "Rs 1499 onwards,
  30 minutes of audio".
* Tier gate copy is correct: *"Your tier does not carry video
  minutes yet."*
* `request_call`'s admin notification fires: *"New call request -
  Wish: Request a live session"*, "just now".

### V.2 THE REAL DEFECT - TWO CALENDARS, TWO ANSWERS

cal.com is **still the entire scheduling path**, despite removal
having been approved long ago.

* Admin toast: *"Accepted. <member> will now pick their slot on
  your cal.com calendar."*
* Admin cards: *"Waiting for them to pick a slot on cal.com."*
* The member leaves Ivory for Chrome, books on cal.com, then is
  asked by Ivory *"Which day did you book?"* and must **re-enter
  the slot by hand** ("TELL IVORY").

**Result: the two surfaces disagree.** For the same member and
the same session -

| surface | time |
|---|---|
| cal.com booking + its email | **8 Oct, 2:30-3:00 am IST** |
| Ivory member sheet | **7/10, 21:00** |

The hand-re-entry step is the bug. Any slip, or any later
reschedule on cal.com, desynchronises them silently.

**It also bypasses the booking rules.** The 4-hour buffer and the
12:00-03:00 window live in `request_call`. cal.com and
`set_call_time` never pass through it, so nothing checked the
2:30 am slot - it was legal by luck, not by enforcement.

**Other cal.com damage:** the owner's personal email is published
as Organizer on every invite; a custom question renders as
**"Where: Yes"**; the email field showed "This field is required"
while visibly filled; Gmail renders a "Directions" button and
"Unable to load event".

### V.3 OWNER'S INSTRUCTIONS, 7 Oct 23:13

1. **Push to her real phone when a member asks for a call.** In-app
   only is useless - she may not open Ivory for hours and wants to
   approve quickly, knowing who and when.
2. **Push to the member's real phone when she approves.** In-app as
   well is fine, but the handset notification is required.
3. **The junk call rows (Mamta_Nancy etc.) are from failed testing
   and are to be LEFT ALONE for now.** She will clear them once
   the app is commissioned. Do not write cleanup SQL yet.
4. cal.com double-booking mess - confirmed by her independently.

### V.4 PLAN AGREED

* **A - push to handsets** (her 1 and 2). Inspect first: the app
  already writes `notifications` rows and a `send-push` edge
  function already exists, so the missing piece is the bridge.
  `sprint25m_push_plumbing.sql`.
* **B - remove cal.com.** Member picks the slot inside Ivory,
  written via `set_call_time`, both sides read one row. Restores
  the booking rules as the only gate.
* **C - junk cleanup.** Parked at her instruction.


### V.5 THE PUSH CHAIN ALREADY EXISTS - 25m result

Nothing needs building. Found on the live database:

* **trigger `trg_notifications_push` on `public.notifications`
  -> `trg_queue_push()`** - every notification row should queue a
  push.
* functions `kick_push_sender()`, `prune_push_queue()`,
  `notify_new_post()`, `notify_wish_update()`.
* tables `device_tokens` (`token`, `device_name`) and
  `push_queue` (`token`).
* extensions **pg_net 0.20.4**, **pg_cron 1.6.4**,
  **supabase_vault 0.3.1**.

`notify_new_post()` only ever **inserts a notifications row** -
it never calls the push service itself. So the push is driven
entirely by the trigger on `notifications`. Since `request_call`
and `respond_call` also insert into `notifications`, pushes
should already fire for calls. They do not.

**Three candidates, settled by `sprint25n_push_why.sql`:**

1. `trg_queue_push` may only handle **broadcast** rows
   (`audience in ('all','tier')`) and silently skip
   `audience = 'user'` with a single `user_id` - which is exactly
   what every call notification uses.
2. No row in `device_tokens` for the admin and/or the member.
3. The `pg_cron` job draining `push_queue` is not scheduled or
   not active.

### V.6 OWNER'S FULL SESSION-LIFECYCLE SPEC - 7 Oct, verbatim intent

**This is the specification for the rest of the call chain.**

**1. A reminder ladder, phone AND in-app, scaled to how far away
the session is.** Her examples:

* booked ~3 days out -> 2 days before, 1 day before, 6 hours
  before, 30 minutes before, 10 minutes before
* booked ~6 hours out -> 2 hours before, 30 minutes before,
  10 minutes before

**Generalised rule (mine, matching her intent): keep a table of
reminder offsets - 2d, 1d, 6h, 2h, 30m, 10m - and for any booking
fire every offset that is strictly less than the lead time.** One
row per offset per call, so none can fire twice. The offsets must
be editable data, never constants (U.20).

**The 10-minute reminder is universal** - she stated it applies to
every session regardless of lead time. It is the one that tells
both sides to come and tap JOIN.

**2. The door and presence.** Whoever arrives first waits; **the
other side is notified that the first person is already there**,
so they can come in. `call_policy.open_early` is already 5
minutes and already honoured by `call_window`.

**3. The timer starts when they are connected**, not at the
scheduled time.

**4. Duration is data.**
* Wish sessions: **30 minutes today, she may raise it** - must
  stay editable (`wish_categories.minutes`).
* Top tier: **120 video minutes/month**, **480 audio
  minutes/month** (120/week) - already live in
  `call_entitlements` after 25k.

**5. After a session, a paid subscriber must see their REMAINING
BALANCE for the month.** `call_balance()` already returns
`remaining`, `resets_at` and `period` - surface it, do not
recompute it.

**6. Extension prompts, raised BY HER, shown to the member.**
* **Wish members:** a window appears **5 or 10 minutes before the
  session ends**, carrying **both the duration and the price**.
* **Premium members:** when they are close to exhausting their
  monthly allowance, the same offer appears with **the premium
  duration and premium price**.
* Dials already exist: `payment_settings.ext_block_minutes` /
  `ext_price_inr` and `ext_block_minutes_premium` /
  `ext_price_inr_premium`, plus `max_ext_per_call` (currently 2).
  **All four prices are still Rs 0 - she must set them.**
* Standing rule unchanged: **the call is never cut off
  mid-sentence and nothing is auto-billed.** Accept and pay for
  one more block, or decline and it ends at the boundary.

**Note the ordering dependency:** the extension prompt needs a
live timer and a known end time, which needs the slot to be
single-sourced - so **cal.com removal must land before the
extension prompts are wired.**

<!-- END OF FILE - IVORY_HANDOVER_7.md -->
