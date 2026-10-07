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


<!-- END OF FILE - IVORY_HANDOVER_7.md -->
