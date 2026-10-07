# IVORY HANDOVER - PART 8

Continues IVORY_HANDOVER_7.md. Parts 1-6 remain valid; read
Part 7 first for the call-chain state, the 30-day reminder
ladder (V.8) and the owner-triggered extension offer (V.9).

This part covers one thing: **why no push notification has
reached a handset since 29 September, and the two repairs that
fix it.**

### V.12 THE ACTUAL CAUSE - 401 MISSING_CREDENTIALS

`net._http_response`, every attempt, identical:

```
status 401
{"source":"@supabase/server","code":"MISSING_CREDENTIALS", ...
```

`cron.job_run_details` shows `ivory-send-push` **succeeded**
every minute - pg_cron was never at fault. Its command is
`select public.kick_push_sender();`, and
`ivory-call-reminders` runs `select public.remind_calls();`.

**"Verify JWT with legacy secret" was already OFF** - confirmed
on the dashboard, 7 Oct 23:59. The toggle was never the problem.

**The real cause:** `kick_push_sender()` sent only
`Content-Type` and `x-ivory-key`. **Supabase's gateway now
requires an `Authorization` or `apikey` header on every edge
function call, even when verify_jwt is off.** No credential
header, so the gateway answered 401 and the function body never
ran. Ivory's code did not change; the platform's front door did.
That is why it worked, then silently stopped on 29 Sep.

**The fix, `sprint25r_fix_push.sql`:** store the **anon** key in
Supabase Vault as **`ivory_anon_key`**, and have
`kick_push_sender()` read it with
`select decrypted_secret from vault.decrypted_secrets` and send
both `apikey` and `Authorization: Bearer <key>`. **No secret is
written into the function body or exposed in chat.** The anon key
is the correct choice - it already ships inside the APK.
**Never put `service_role` in a function.**

**THE GENERAL LESSON - applies to `agora-token`, `r2-vault`,
`rzp-create-order`, `rzp-verify-unlock` too: any edge function
called from inside Postgres via pg_net must now send a credential
header.** If joining a call or unlocking the vault ever fails
silently, check `net._http_response` for 401 MISSING_CREDENTIALS
first - the same breakage may be waiting in those paths. Nobody
has noticed yet because no call has got far enough to test them.

Five edge functions exist: `agora-token` (7 days old),
`r2-vault` (1 day), `rzp-create-order` (1 day),
`rzp-verify-unlock` (3 days), `send-push` (8 days).

### V.13 THE SECOND FAULT - send-push WAS THE TEMPLATE

After 25r fixed the credential header, the reply changed from
401 to:

```
200  {"message":"Hello undefined!"}
```

**That is Supabase's hello-world starter template.** The function
deployed as `send-push` was never Ivory's sender. It returned 200
to everything, which is exactly why `push_queue.last_error`
stayed empty - the call "succeeded" every time and delivered
nothing.

`send-push` was last updated **8 days ago**; the queue starts
backing up **29 Sep**. Same moment. The real sender was
overwritten by the blank template.

**So there were TWO stacked faults:**
1. missing `Authorization`/`apikey` header - fixed in 25r;
2. no sender behind the door - fixed by
   `edge/send-push/index.ts` (8,107 B).

Confirmed healthy and NOT at fault: the Flutter FCM integration
(6 tokens registered, admin included), `trg_queue_push`,
notification creation, pg_cron, pg_net.

**THE NEW `edge/send-push/index.ts`:**
* **Zero imports** - pure `fetch` against PostgREST and Google.
  Nothing to break on a CDN, nothing to version-pin.
* Checks `x-ivory-key` (env `IVORY_PUSH_KEY`, defaults to the
  existing `ivory-7f3k9q2m-push`).
* Mints a Google OAuth2 token by signing a JWT with WebCrypto
  (`RSASSA-PKCS1-v1_5` / SHA-256) from the service account's
  PKCS8 private key. **Token cached in memory until 60 s before
  expiry.**
* Sends via **FCM HTTP v1** -
  `https://fcm.googleapis.com/v1/projects/<id>/messages:send`.
  **The legacy FCM server-key API is dead - v1 is the only
  option, which is why a service account is required.**
* Oldest 100 unsent rows per run; cron fires every minute.
* Marks `sent_at` on success; on failure **increments `attempts`
  and writes `last_error`** - the queue can never go silent
  again.
* **Deletes device tokens FCM reports as UNREGISTERED / 404** so
  dead handsets self-clean.
* Returns a JSON summary: `looked_at`, `sent`, `failed`,
  `dead_tokens_removed`.

**ONE SECRET MUST BE SET:** Edge Functions -> Secrets ->
`FCM_SERVICE_ACCOUNT` = the entire Firebase service account JSON.
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected by
the platform automatically.

**Project id is read from the JSON** - nothing else to configure.

### V.14 AFTER DEPLOY - TIMEOUT, AND A TOGGLE THAT FLIPPED BACK

Owner deployed the real sender 8 Oct 01:17 ("Successfully
deployed edge function"). Two things then showed up.

**1. THE TOGGLE RE-ARMED ITSELF.** The 01:17 Settings screenshot
shows **"Verify JWT with legacy secret" switched back ON
(green)** - it had been confirmed OFF at 23:59. **Redeploying a
function can reset this.** It must be **OFF**: the description on
that very screen says *"The anon key satisfies this"*, and Ivory
now sends the **publishable** key, a newer type that does **not**
satisfy a legacy-JWT check. Left on, the 401 returns.

**CHECK THIS TOGGLE AFTER EVERY REDEPLOY of send-push,
agora-token and r2-vault.**

**2. `Timeout of 5000 ms reached`, status NULL.** This is
progress, not regression - the 401 is gone and pg_net is now
waiting on a function doing genuine work (OAuth token, then
sequential FCM sends). pg_net's default patience is 5000 ms.
**The sender very probably kept running and delivered; the
database just stopped listening for the answer.**

**The paired fix:**
* `sprint25t_timeout.sql` - `timeout_milliseconds := 25000` on
  the `net.http_post`, plus an early return when the queue is
  empty so idle minutes cost nothing.
* `edge/send_push.ts` - **`BATCH` lowered from 100 to 25.**

25 sequential sends finish inside a 25 s wait; cron fires every
minute, so **two runs cannot overlap and double-send**. 25/min
clears the 218 backlog in about nine minutes.

**NOTE ON THE LOCAL TREE: `edge/send-push/index.ts` was dropped
by the sandbox rollback (the recurring hazard). It was recreated
as `edge/send_push.ts`, matching the flat naming of
`r2_vault.ts`, `rzp_create_order.ts`, `rzp_verify_unlock.ts`.
The deployed copy on Supabase was unaffected.**

### V.15 THE FUNCTION WAS RENAMED - send_push, UNDERSCORE

8 Oct 01:42. The deployed function is now
**`send_push` (underscore)**, not `send-push`:

```
https://soephrftgddbwkzwjddj.supabase.co/functions/v1/send_push
```

Caused by naming the workspace file `edge/send_push.ts` to match
the flat style of `r2_vault.ts`. **`kick_push_sender()` was still
posting to the hyphen name, which no longer exists - every call
would 404.** `sprint25u_send_push_url.sql` points it at the
underscore name and supersedes `sprint25t_timeout.sql` (it
carries the same 25000 ms timeout and empty-queue early return).

**THE FIVE EDGE FUNCTIONS ARE NOW:** `agora-token`, `r2-vault`,
`rzp-create-order`, `rzp-verify-unlock` (all hyphens) and
**`send_push` (underscore)**. The odd one out. Anything calling
it must use the underscore.

Toggle confirmed **OFF** on `send_push` at 01:42.

### V.16 THE SERVICE ACCOUNT - VALID, AND A NOTE ON SIZE

File `ivory-97146-firebase-adminsdk-fbsvc-c03174ea57.json`,
2,373 B, parsed clean. All eleven fields present.
**`project_id` = `ivory-97146`**,
`client_email` = `firebase-adminsdk-fbsvc@ivory-97146.iam...`.
The function reads `project_id` from this JSON, so nothing else
needs configuring.

**It is much larger than the publishable key because it embeds a
2048-bit RSA private key (~1,700 chars).** That is expected, not
a fault. Paste it exactly as downloaded - first character `{`,
last `}`.

**THE "json" TRAP:** the owner's viewer displayed the word
**`json`** above the content (a format label, not file content)
and it was pasted into the secret on the first attempt. That
would have broken `JSON.parse`. **Markdown fences and format
labels must never go into a secret value.** She caught it
herself before it cost a round.

**SECURITY DEBT - OPEN:** the service account private key was
uploaded into the agent workspace, so it should be treated as
exposed. **Once push is confirmed working, generate a new
private key in Firebase (Project settings -> Service accounts),
update the `FCM_SERVICE_ACCOUNT` secret, and DELETE the old key
from the Service accounts list.** Unlike the publishable key,
this one can send on behalf of the project.

### V.17 PUSH IS WORKING - FIRST DELIVERY SINCE 29 SEP

8 Oct 01:53, after `sprint25u`:

```
still_stuck 212    sent 6    tries 29
any_error: 404 {"error":{"code":404,"message":"NotRegistered"
```

**`sent 6` is the proof.** Six notifications reached real
handsets. The full chain is verified: notification insert ->
`trg_queue_push` -> `push_queue` -> pg_cron -> `kick_push_sender`
-> credential header -> `send_push` -> Google OAuth2 (JWT signed
with WebCrypto) -> FCM HTTP v1 -> device.

**The `FCM_SERVICE_ACCOUNT` secret is correct and must not be
repasted.** Those 6 could not have been signed otherwise - a
malformed private key fails at the OAuth step before any send.

**THE REMAINING 212 ARE UNDELIVERABLE, NOT BROKEN.**
`404 NotRegistered` = that handset no longer exists. **Each
reinstall of the test APK over the eight-day outage killed the
previous token.** Only 6 tokens are live, and all 6 were served.

**THE RETRY LEAK (fixed).** A dead-token row failed, bumped
`attempts`, but never received `sent_at` - so cron retried it
every minute indefinitely (`tries` had reached 29). Two fixes:

* `edge/send_push.ts` - `markFailed()` now takes a **`giveUp`**
  flag. When Firebase reports the handset gone, the row gets
  `sent_at` as well as `last_error`, closing it permanently.
  **A NotRegistered token can never succeed on retry.**
* `sprint25v_clear_backlog.sql` - deletes unsent rows whose
  token is no longer in `device_tokens`, deletes anything unsent
  from before 8 Oct 01:00, and clears delivered rows over three
  days old. **Touches only the push outbox - no call_requests,
  nothing the owner parked.**

**OPERATIONAL NOTE: `device_tokens` will accumulate dead rows
every time the APK is reinstalled.** The sender now self-cleans
(deletes on 404/UNREGISTERED), so this should not recur. Expect
`live_handsets` to drop toward the number of genuinely installed
devices after the first full pass.

**STILL OWED: rotate the Firebase private key** (V.16).

### V.18 CONFIRMED ON A HANDSET - 8 Oct 02:04

**A real Android notification appeared in the tray with the app
closed:**

```
Ivory - now
A session is near
Your session with Ivory begins at 02:30 AM.
Open Ivory and tap Join a little before.
```

**Point A of the 7 Oct list is functionally proven.** The
source was `remind_calls()` (cron `ivory-call-reminders`, every
5 min) - it had been writing these notifications throughout the
outage with nowhere to deliver them.

After `sprint25v`: **`still_queued 0, delivered 6,
live_handsets 4`** - two dead tokens culled automatically by the
new give-up path. The outbox is clean.

**OPEN: the ADMIN handset has received nothing.** Two signals:
the delivered copy is member-facing (*"Your session with
Ivory"*), and `live_handsets` fell 6 -> 4 during cleanup, so an
**admin token may have been culled as NotRegistered**. With no
admin token there can be no admin push, and **nothing in the
logs would look wrong** - the queue would simply never contain a
row for her.

`sprint25w_admin_test.sql` lists tokens by role and sends one
real test notification to every `profiles.role = 'admin'`.

**IF THERE IS NO ADMIN TOKEN:** the fix is on the device - open
Ivory on the admin phone, allow notifications, and let the app
re-register. **Every APK reinstall invalidates the previous
token**, so this will recur through testing. Worth adding a
visible "notifications are on / off" indicator to the admin
screen later so this is never silently broken again.

**ALSO VISIBLE IN THE 02:04 SHADE - the cal.com damage, again:**
a Google Calendar entry *"Ivory Live Video Session be..."*
02:30-03:00 attributed to **`chawdhu...`** - her personal
address, on the member's phone, exactly as recorded in V.2.
Independent confirmation that cal.com removal (block B) must be
next.

### V.19 BLOCK A CLOSED - ADMIN PUSH CONFIRMED ON DEVICE

8 Oct 02:13, admin handset notification shade, app closed:

```
Ivory test         2m   If this reached your phone, admin push i...
Ivory test         3m   If this reached your phone, admin push i...
A session is near  9m   Your session with Ivory begins at 02:30 ...
```

Queue rows: both tests `sent_at` set, **`attempts 0`**, no error.

**BLOCK A OF THE 7 OCT PLAN IS COMPLETE AND DEVICE-VERIFIED** -
owner's points 1 and 2 both satisfied. Admin and member handsets
both receive pushes with the app closed.

**THE FULL REPAIR, FOR THE RECORD - two stacked faults:**

| # | Fault | Fix |
|---|---|---|
| 1 | Supabase's gateway began requiring an `Authorization`/`apikey` header on every edge call. `kick_push_sender` sent neither, so the gateway answered **401 MISSING_CREDENTIALS** and the function body never ran - hence `attempts 0`, `last_error` empty, for 8 days | publishable key in Vault as `ivory_anon_key`; both headers added (25r) |
| 2 | The deployed `send-push` was Supabase's **hello-world template**, answering `200 {"message":"Hello undefined!"}` and sending nothing | real sender written: `edge/send_push.ts` (25s) |

Plus three follow-ons: pg_net's 5 s timeout raised to 25 s with
`BATCH` cut to 25 (25t), the hyphen/underscore rename (25u), and
the dead-token backlog cleared with a give-up path so
`NotRegistered` rows are never retried forever (25v).

**NOTHING IN IVORY'S OWN LOGIC WAS EVER WRONG.** The trigger,
the queue, the targeting, the Flutter FCM registration and
pg_cron were all correct throughout.

**WHAT NOW WORKS WITHOUT FURTHER CODE:** every existing
`notifications` insert reaches handsets - call requests,
confirmations, slot changes, `remind_calls()` reminders, and
"Ivory is live now". **The 30-day reminder ladder (V.8) and the
owner-triggered extension offer (V.9) can now be built on a pipe
that is proven.**

**STILL OPEN:**
* Rotate the Firebase private key (V.16) - the file was shared.
* **BLOCK B - remove cal.com.** Confirmed again at 02:13: the
  member's shade shows a calendar entry
  *"Ivory Live Video Session be..."* 02:30-03:00 attributed to
  **`chawdhu...`**, her personal address. This is the next
  block.
* Later nicety: a notifications on/off indicator on the admin
  screen, since every APK reinstall invalidates that handset's
  token silently.

## PART W - BLOCK B: cal.com REMOVED

### W.1 WHAT 25x DOES

**`member_pick_slot(call_id_in bigint, slot_in timestamptz)
returns text`** - the member chooses their time inside Ivory and
this is **the only gate**. One row, one answer, both screens
agree. Replaces the cal.com round trip and the hand-retype step
(`confirm_my_booking`).

Checks, in order, all with member-readable messages:
1. the call belongs to `auth.uid()` - else *"That session is not
   yours."*
2. status not in `declined/cancelled/done/missed`
3. **at least `min_notice_hours` from now**
4. **within `max_days_ahead`**
5. **inside the hours the house keeps**, a window that wraps
   past midnight: `hour >= open_from_hour or hour < open_to_hour`

Then writes `requested_for` **and** `window_end = slot +
minutes`, and notifies **every** `profiles.role = 'admin'` - so
the owner now gets a push the moment a member picks a time.

### W.2 THE RULES ARE NOW EDITABLE DATA

Added to `call_policy` (idempotent, with the agreed defaults):

| column | default | meaning |
|---|---|---|
| `min_notice_hours` | 4 | the buffer |
| `open_from_hour` | 12 | window opens (IST) |
| `open_to_hour` | 3 | window closes next morning (IST) |
| `max_days_ahead` | 30 | booking horizon |

**No literal hours anywhere in the function.** The window is
evaluated in `Asia/Kolkata` via
`slot_in at time zone 'Asia/Kolkata'`, so it is correct
regardless of the member's device clock or locale.

### W.3 THE DART SIDE

* **`lib/widgets/call_book_flow.dart` REWRITTEN** (8,293 B).
  `url_launcher` gone, cal.com gone. Three steps: an hours card
  explaining the window and the earliest possible time, then the
  date and time pickers themed to the house palette, then a
  confirm card showing the chosen time and the minutes.
  **`bookCallSlot(context, c, say:, reload:)` keeps its exact
  signature**, so the only call site
  (`call_wish_sheet.dart:112`) is untouched.
* **`lib/services/live_service.dart`** - `confirmBooking` /
  `confirm_my_booking` replaced by **`pickSlot(callId, when)`**,
  which returns the sentence the database gives it.
* **`lib/screens/admin_calls_tab.dart`** - the two cal.com
  strings replaced: *"will now choose their time inside Ivory"*
  and *"Waiting for them to choose their time"*. **No "cal.com"
  remains anywhere in `lib/`.**

**Refusals reach the member through `houseMessage(e)`** - never
raw Postgres text (B6 discipline).

### W.4 LEFT DELIBERATELY IN PLACE

`bookingLink()` / `saveBookingLink()` and the `BookingLink`
model still exist in the service and the admin screen. They are
now unused by the booking path. **Left alone on purpose** - this
sprint changes behaviour, not structure. Remove them in a later
tidy once the new flow is confirmed on a device.

**`admin_calls_tab.dart` is 16,510 B / 511 lines - over the
500-line guide but under the 18 KB ceiling.** It was already at
that length; this sprint only changed two strings. Next
substantive change there should lift a responsibility out.

### W.5 WHAT THIS FIXES, OUT LOUD

* no second calendar to disagree with the first
* **the 4-hour buffer and the 12:00-03:00 window are now
  genuinely enforced** - they were bypassed entirely
* the owner's personal address no longer appears as Organizer
* no "Where: Yes" artifact, no "Directions" button, no
  "Unable to load event"
* no hand-retyping of a time already chosen
* reschedules can no longer happen invisibly outside Ivory
* **the owner is pushed the moment a slot is picked**

<!-- END OF FILE - IVORY_HANDOVER_8.md -->
