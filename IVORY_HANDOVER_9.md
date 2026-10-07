# IVORY HANDOVER - PART 9

Continues IVORY_HANDOVER_8.md (the push repair and the cal.com
removal). Parts 1-7 remain valid.

This part is the **8 October 03:00 live two-handset test**: what
finally worked, the three defects fixed the same night, and the
six the owner found that are still open.

## PART X - THE 8 OCT 03:00 TWO-HANDSET TEST

### X.1 WHAT WORKED

* **The new in-app picker ran end to end.** "Choose your time"
  appeared, member chose, sheet moved to Confirmed with JOIN.
  **No cal.com anywhere.** Admin toast: *"Accepted.
  Yourpritz24SixReal will now choose their time inside Ivory."*
* **Admin now reads correctly: "Agreed for 8 Oct, 12:00 pm".**
* Two-way Agora video, mute/camera/flip/hang-up, the privacy
  gate *"Just between us"*, and a running timer (0:42 -> 3:47).
* `respond_call`, `member_pick_slot` and the admin notification
  all fired.

### X.2 DEFECT - MEMBER TIMES WERE SHOWN IN UTC (fixed)

`call_wish_sheet._when` formatted the raw UTC value with **no
`toLocal()`**, while `admin_calls_tab._when` **does** call it.
Hence the same session read:

| screen | shown | truth |
|---|---|---|
| admin | 8 Oct, 12:00 pm | correct |
| member | Window 8/10, 06:30 to 07:00 | 06:30 **UTC** = 12:00 IST |

**THIS ALSO EXPLAINS THE 7 OCT "cal.com drift".** The member
sheet said *7/10, 21:00*; cal.com said *8 Oct 2:30 am*. 21:00
UTC **is** 02:30 IST. **The two systems never disagreed - Ivory
was printing UTC.** cal.com removal remains right, but the
5.5-hour gap was ours.

**Fix:** new **`lib/widgets/call_sheet_bits.dart`** holds
`ivoryWhen()` and `ivoryClock()`, both `toLocal()` first, plus
the `CallStep` widget lifted out of the sheet. **Any new
member-facing time must use these - never format a raw
DateTime.**

### X.3 DEFECT - AN IMPOSSIBLE "EARLIEST" (fixed)

At 03:15 the dialog offered *"The earliest you can choose is
8 Oct, 7:15 am"* - inside the closed hours. Now
`_firstOpening()` rolls the notice period forward to the next
open moment, and the time picker starts there.

### X.4 DEFECT - STALE cal.com COPY (fixed)

Step 2 of HOW IT WORKS still read *"my calendar opens for you"*.
Now: *"choose your day and time right here in Ivory."*

### X.5 OWNER'S FINDINGS, 8 OCT 03:25 - STILL OPEN

**O1. NO HANDSET PUSH, EITHER SIDE.** Both shades empty at
03:13/03:18 though the in-app inboxes filled. Push was proven at
02:13, so this is a regression **after the new APK install** -
the prime suspect is token replacement: a reinstall kills the
old address, `send_push` now deletes dead addresses, and if
neither phone re-registered there is nobody to deliver to.
**Read with `sprint25y_push_silent.sql`.**

**O2. THE INBOX DOES NOT REFRESH ITSELF.** Messages appear only
after a manual pull. Needs the 24q revision-listener treatment
or a realtime subscription on `notifications`.

**O3. HANG-UP FREEZES THE OTHER SIDE.** Admin ends cleanly;
**the member is left on a frozen frame reading "The stream has
paused"** and must back out by hand. **The same fault exists in
the live broadcast** and predates this sprint. The remote-left
event is not being turned into a clean exit.

**O4. THE EXTENSION OFFER IS UNREACHABLE DURING A CALL.** It
lives only in the admin CALLS tab, and the call screen cannot be
left without ending the call. **Owner's requirement, verbatim:**
a control **on the call screen**; tapping it pops a small form
with **price AND duration** and a **SEND** button; it appears on
the member's screen **in front of them**, holds **30 seconds**
(revised down from 1 minute), and **may be sent repeatedly**.
Nothing may be deferred to the inbox - *"once they end the call
and then check their messages, the proposal makes no sense."*

**O5. DURATION IS MISSING.** "Offer more time" shows only a
price box (prefilled 999). The owner must set **both** price and
duration, clamped 30-120.

**O6. ACCIDENTAL HANG-UP ENDS A PAID SESSION.** Owner's
question: if someone taps the red button by mistake with
minutes still owed, the session is over and the time is lost.

**AGREED ANSWER - SEPARATE "LEAVING" FROM "ENDING":**
hanging up should only *leave the room*. The session stays open
until **either** the paid minutes are used **or** the owner taps
an explicit **END SESSION**. Whoever left sees **REJOIN**, and
**the timer continues from the minutes already spent rather than
restarting** - so a misfire costs seconds, not the session. The
other side is told *"they dropped out - the room is still
open"*. This also makes a dropped network indistinguishable from
a mistap, which is the behaviour a paying member expects.

### X.6 ORDER OF WORK AGREED

1. **25z (this sprint)** - UTC fix, impossible-earliest fix,
   stale copy, and the push diagnostic.
2. **O3** clean exit on hang-up, both call and broadcast.
3. **O6 + O4 + O5** the session-lifecycle sprint: leave vs end,
   REJOIN with a resuming timer, and the in-call extension card
   carrying price and duration, 30-second hold, repeatable, over
   both video and audio.
4. **O2** inbox auto-refresh.
5. **O1** whatever 25y reveals.

**Also still open:** the Rs.999 default on the extension box
while `payment_settings` holds Rs.0 in all four price columns -
that figure is coming from somewhere else and must become data.

<!-- END OF FILE - IVORY_HANDOVER_9.md -->
