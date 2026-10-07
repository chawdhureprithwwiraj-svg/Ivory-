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

<!-- END OF FILE - IVORY_HANDOVER_8.md -->
