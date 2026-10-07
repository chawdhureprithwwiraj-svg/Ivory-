# IVORY - HANDOVER PART 6

Continues IVORY_HANDOVER_5.md. Parts 3, 4 and 5 still stand; this
part holds the call-chain truth read directly out of the database
on 7 Oct 2026, and supersedes the design notes in Part 5 section T
wherever the two disagree.

Everything here was read from `pg_get_functiondef`, not guessed.

### U.5 THE FOURTEEN SIGNATURES - verified 7 Oct 20:37, 25c

Exactly as the database reports them. Treat this as law; do not
guess an argument name again.

```
adjust_call_usage(member_in uuid, kind_in text, <int>) -> void
call_balance(kind_in text)
    -> TABLE(kind text, allowed integer, used integer, ...)
call_window(call_id_in bigint)
    -> TABLE(state text, opens_at timestamptz, ...)
end_call(call_id_in bigint) -> void
join_call(call_id_in bigint) -> text
list_calls(status_in text) -> SETOF admin_calls
mark_call_missed(call_id_in bigint) -> text
remind_calls() -> integer
request_call(kind_in text, minutes_in integer,
             price_in integer, note_in text,
             when_in timestamptz) -> bigint
respond_call(call_id_in bigint, accept_in boolean) -> text
set_call_time(call_id_in bigint, when_in timestamptz) -> void
set_call_time(call_id_in bigint, when_in timestamptz,
              window_end_in timestamptz) -> void
submit_call_extension_payment(call_id_in INTEGER, utr_in text,
                              shot_in text) -> bigint
sweep_missed_calls() -> integer
```

**TWO DEFECTS ARE VISIBLE IN THIS LIST ALONE.**

**1. The `set_call_time` pair - the M4 suspect.** The difference
between the overloads is the third argument, `window_end_in`. The
two-argument version sets a start with **no end**. `call_window`
returns a `state` computed from a window - and a window with no end
cannot compute a state, so the slot renders as nothing on both
sides. **This matches M4 exactly.** If Dart calls the two-arg form,
that is the whole bug. Confirm against the bodies (25d), then drop
the loser with its full arg list.

**2. `submit_call_extension_payment` takes `call_id_in INTEGER`**
while `call_requests.id` is **bigint** and every other function
takes bigint. Postgres will not always resolve a bigint argument to
an integer parameter, and Supabase RPC sends JSON numbers - this is
a live crash or silent no-op on the extension path. It must be
redefined as bigint (drop the integer version explicitly).

Also note `call_balance` and `list_calls` are **already
data-driven** - `call_balance(kind_in)` returns `allowed` from the
tier tables. The no-hardcoded-minutes rule is already satisfied by
the existing engine. Do not reimplement it.

### U.6 M4 SOLVED - root cause, from the 25d source dump

**`set_call_time` was never callable.** The two overloads are:

```
set_call_time(bigint, timestamptz)
set_call_time(bigint, timestamptz, timestamptz DEFAULT NULL)
```

The three-argument one carries a **DEFAULT** on its third argument.
A call written `set_call_time(id, when)` therefore matches **both**.
Postgres rejects an ambiguous call outright - SQLSTATE **42725**,
"function is not unique" - and performs no update. Setting a call
time has failed **100% of the time since both were created**. That
is M4 entire: the slot was never saved, so there was nothing for
either side to display.

**APPLIED 7 Oct 2026, 21:25 - the owner ran the drop and Supabase
returned "Success. No rows returned", which is the correct result
for a DROP.** **CONFIRMED 21:29: the count query returned exactly ONE row,
`call_id_in bigint, when_in timestamptz, window_end_in
timestamptz`.** If it ever shows two rows again, someone has
re-created the overload.

**Fix: `sprint25e_fix_m4.sql` drops the two-argument version.** The
identical call then resolves to the three-argument one with
`window_end_in` defaulting to null. **No Dart change, no new APK.**
Keep the 3-arg: it also sets `window_end` and writes a better
notification.

A second, quieter bug the 2-arg version had: it set
`requested_for` **without clearing `window_end`**, so a rescheduled
call kept its old window.

### U.7 OTHER FACTS FROM THE SOURCE - correct earlier assumptions

**A table nobody mentioned: `public.call_policy`,** row `id = 1`,
columns `open_early` (default used: 5 min) and `grace_minutes`
(20). `call_window` reads it. **The join window is already built
and already data-driven** - 25f does not need to invent it, only to
set the values.

**`call_window` computes `state` as `early` / `open` / `closed`**
from `requested_for - open_early` to
`requested_for + minutes + grace_minutes`, widened by `window_end`
when present. Returns `anytime` when no slot is agreed (it
deliberately does not lock anyone out) and `closed` for a missing
id. This is sound; do not rewrite it.

**THE ENGINE USES `requested_for`, `window_end` AND `minutes` -
NOT the columns 25b added.** `slot_at`, `duration_mins` and
`confirmed_at` are unused by every function read so far.
**Do not migrate the engine onto them.** Write new code against
`requested_for` / `window_end` / `minutes`. The 25b columns are
harmless but currently dead.

**`request_call` has three real defects:**

1. `price_in integer DEFAULT 999` - **a hardcoded price**, against
   the data-driven rule. Must come from the tier tables.
2. It applies **no scheduling guard at all** - no 4-hour buffer and
   no 12:00-03:00 IST window. A member can book any time.
3. Its duplicate-guard checks `status in
   ('requested','accepted','active')` but `request_call` inserts
   with **no status at all**, relying on the column default. Verify
   the default is `requested`, or the guard never fires.

**`respond_call` is correct** - admin gate, generates
`channel_name` as `ivorycall-<id>-<10 hex>`, sets `accepted` or
`declined`, notifies the member. Leave it alone.


### U.8 SUPABASE SHOWS ONLY THE LAST STATEMENT'S RESULT

Burned twice now. A script of five `select`s runs all five and
**displays only the fifth**. Every inspection script must be **ONE
statement** - `union all` the parts together with a common
`(part, detail, extra)` text shape, as 25b and 25g do. Chunk any
long value with
`cross join generate_series(0, n) as g(i)` + `substr(..., i*60+1, 60)`.

### U.9 TIER TABLE IS THINNER THAN ASSUMED

`subscription_tiers` was searched for any column matching price,
min, call or inr. **Only one matched: `price_inr integer`.**

There is **no per-tier call-minute column**. So the allowance that
`call_balance(kind_in)` returns as `allowed` comes from somewhere
else - `call_policy`, or a table not yet found. 25g dumps
`call_balance`'s source to settle it. **Do not write the
request_call repair until that is known**, or the hardcoded 999
will simply be replaced by a different guess.

### U.10 THE "name" TYPE TRAP - cost one whole run

A `union all` takes its column type from the **first** branch. In
25g that branch was `information_schema.columns.column_name`, whose
type is **`name`** - a fixed **63-byte** type, not text. Postgres
typed the entire union column as `name` and **silently truncated
every row to 63 characters**. For indented function source, the
first 63 characters are whitespace, so every line arrived blank.
No error, no warning.

**Rule: in any `union all` reporting query, cast EVERY branch
explicitly with `::text`,** and strip indentation with
`regexp_replace(src, '^[ \t]+', '')` before returning source code.

### U.11 CONFIRMED VALUES - 7 Oct, 25g

* **`call_policy` id=1**: `open_early 5`, `grace_minutes 20`,
  `free_no_shows 2`, updated 30 Sep. The join window is live and
  data-driven. **25f/25g do not need to build it.**
* **`call_requests.status` defaults to `'requested'`, not null.**
  So the one-open-session guard inside `request_call` *does* fire.
  That suspected defect is **cleared** - it was a false alarm.
* **`subscription_tiers` in full**: `id`, `name`, `description`,
  `price_inr`, `duration_days`, `level`, `perks` (ARRAY),
  `is_active`, `created_at`.
  **There is NO call-minute column anywhere in the tier table.**
  So `call_balance`'s `allowed` is sourced elsewhere - another
  table, the `perks` array, or hardcoded inside the function. If
  it is hardcoded that is a **second** breach of the data-driven
  rule, alongside `request_call`'s `DEFAULT 999`.

### U.12 THE ALLOWANCE ENGINE - read in full, 25h. IT IS SOUND.

`call_balance(kind_in)` is **already fully data-driven**. Do not
rewrite it. How it works:

1. `public.current_tier_level()` gives the member's level.
2. It selects from **`public.call_entitlements`** where
   `kind = kind_in and is_active and tier_level <= my_level`,
   `order by minutes desc limit 1` - i.e. **the most generous
   entitlement the member's level qualifies for.**
3. The cycle length comes from `e.period`: day / week / year /
   else 30 days. The cycle is anchored to **`public.tier_anchor()`**
   - the day the paid tier began, not the calendar month.
4. Minutes spent are summed from **`public.call_usage`**
   (`member_id`, `kind`, `minutes`, `used_at`) since cycle start.
5. No-shows are counted from `call_requests.status = 'missed'`.
6. **The cycle is clipped to the subscription:** if
   `max(expires_at)` from `user_subscriptions` falls before the
   next reset, the reset becomes the expiry and `period` is
   reported as `'membership'`. Neat, and correct.

Returns `kind, allowed, used, remaining, period, resets_at,
tier_level, no_shows, cycle_start`.

**Note its own comment at lines 21-22:** OUT column names are also
plpgsql variables, so bare `kind` / `tier_level` are ambiguous
(error **42702**). That is why everything is aliased. **Preserve
this when editing any function with OUT parameters.**

### U.13 `member_minute_ledger` IS REDUNDANT - abandon it

25b created `public.member_minute_ledger`. **`public.call_usage`
already exists and is the table `call_balance` actually reads.**
Keeping both invites two sources of truth for the same number.

**Decision: `member_minute_ledger` is abandoned, not used.** Do
not write to it. It can be dropped at Play-build cleanup time.
Record any new usage in **`call_usage`**.

Likewise the 25b columns `slot_at`, `duration_mins`,
`proposed_at`, `proposed_by`, `confirmed_at`, `ext_count` are
**unused by the live engine** (U.7). The engine runs on
`requested_for`, `window_end`, `minutes`.

**Lesson: this is the cost of designing before inspecting. 25b
should have been a read, not a migration.**

### U.14 TABLES THE ENGINE DEPENDS ON - none of which were in §T

`call_entitlements` · `call_usage` · `call_policy` ·
`user_subscriptions` · `subscription_tiers` · `wish_categories`
(has a `minutes` column) · `admin_calls` (a view - `list_calls`
returns SETOF it) · functions `current_tier_level()` and
`tier_anchor()`.

### U.15 WHERE CALL PRICES LIVE - `wish_categories`

`public.wish_categories` columns: `id`, `name`, `tagline`, `icon`,
`minutes`, `base_price_inr`, `delivery_days`, `call_kind`,
`highlight`, `sort_order`, `is_active`, `created_at`.

**`call_kind` is the join to the call engine.** Only two rows have
it set:

* **"Request a live session"** - `call_kind = video`, highlight,
  `sort_order 0`, 30 minutes, **Rs 2,999**
* **"Talk to me on a call"** - `call_kind = audio`, highlight,
  30 minutes

The other five rows (`call_kind` null) are the non-call wishes:
A Story Written For You, A Voice Note, A Private Video Vignette,
A Personal Letter, Surprise Me - priced Rs 999 to Rs 1,499.

**This is where `request_call`'s hardcoded 999 should always have
come from.** 25j rewires it: price and minutes are read from the
category matched on `call_kind`, `is_active`, lowest `sort_order`.
The `price_in` / `minutes_in` arguments remain in the signature
(so the installed APK still binds) but are now **fallbacks only**.

### U.16 ENTITLEMENT ROWS - AND A LIKELY INVERSION. ASK HER.

Only two rows in `call_entitlements`:

| kind | tier_level | minutes | period | note |
|---|---|---|---|---|
| video | **3** | 120 | **week** | "Top tier: live video with me." |
| audio | **4** | 120 | **month** | "Second tier: audio calls with me." |

Tiers are: 1 Ivory Reader Rs 99 - 2 Ivory Listener Rs 299 -
3 Ivory Insider Rs 599 - **4 Ivory Circle Rs 999 (top)**.

**RESOLVED 7 Oct by the owner - the rows were inverted. See
U.19.** Original (wrong) state documented below for the record.

**The notes contradict the levels.** The row calling itself "top
tier" is set to level 3 (Insider), and the "second tier" row to
level 4 (Circle, the actual top). Because `call_balance` matches
`tier_level <= my_level`, the live effect is:

* **Insider (3)** gets **video, 120 min/week** - but **no audio**.
* **Circle (4)** gets video and audio.
* Reader and Listener get nothing.

So the cheaper tier unlocks video weekly while audio is gated to
the most expensive tier, and video is **four times** more generous
than audio (120/week vs 120/month). That is almost certainly
backwards. **It is data, not code - do not silently "fix" it.
Confirm the intended matrix with the owner, then update the rows.**

### U.17 STATE OF THE CALL CHAIN AFTER 25j

* M4 duplicate - **FIXED and confirmed** (25e, 21:29).
* Join window - **already existed**, data-driven (`call_policy`).
* Allowance engine - **already existed**, data-driven
  (`call_entitlements` + `call_usage`).
* Duplicate-request guard - **works** (status defaults
  `requested`).
* `request_call` price + booking rules - **25j, RAN 21:54.**
  Proof returned video Rs 2,999 / 30 min and audio Rs 1,499 /
  30 min, both read from `wish_categories`.
* Entitlement matrix - **25k, RAN 22:00, confirmed correct.**
* **STILL OPEN:** `submit_call_extension_payment(call_id_in
  INTEGER, ...)` while `call_requests.id` is bigint. Must be
  redefined as bigint, dropping the integer version explicitly.
* **STILL OPEN:** the entitlement inversion in U.16.
* **STILL OPEN:** B6, raw exception text reaching members.
* Then the two call sheets.

### U.18 `RAISE` TAKES A LITERAL, NOT AN EXPRESSION

`raise exception 'a' || 'b';` is **invalid** - SQLSTATE 42601,
"syntax error at or near ||". RAISE's message must be a single
string literal (optionally with `%` placeholders and `using`).

Two legal forms:

```
raise exception 'one long literal on a single line';

raise exception 'first part '      -- adjacent literals,
  'second part';                   -- separated by a newline
```

The second is standard SQL string continuation and is what the
original `request_call` used. **Do not "tidy" it into `||`.**
Cost: one failed run, 7 Oct 21:49.

### U.19 THE ENTITLEMENT MATRIX THE OWNER CONFIRMED - 25k

Her words, 7 Oct: *the top tier premium membership is going to
have 120 minutes of video call a month, whereas the second top
tier will have 120 minutes of audio call per week, which adds to
480 minutes of audio a month.*

| kind | tier | period | minutes | effective |
|---|---|---|---|---|
| video | **top** (level 4, Ivory Circle) | month | 120 | 120/mo |
| audio | **second** (level 3, Insider) | week | 120 | ~480/mo |

Because `call_balance` matches `tier_level <= my_level`, the live
effect is: **Circle gets both video and audio. Insider gets audio
only. Reader and Listener get neither.** That is what she asked
for.

**APPLIED AND CONFIRMED 7 Oct 22:00** - the proof query returned
`video / Ivory Circle / level 4 / 120 mins per month` and
`audio / Ivory Insider / level 3 / 120 mins per week`.

`sprint25k_entitlements.sql` applies it. It resolves "top" and
"second top" by `row_number() over (order by level desc)` on
active tiers **rather than writing 4 and 3 literally**, so the
script still lands correctly if tiers are renamed, repriced or
re-levelled later.

### U.20 STANDING INSTRUCTION - NUMBERS ARE PROVISIONAL

The owner, 7 Oct: *the membership plan charges and the
deliverables will be updated and confirmed at the very last
moment. Right now we are just keeping the logic going and setting
up the correct chain so that whatever we edit later, everything
works and goes through smoothly.*

**Therefore: every price, minute count and period must stay
editable data.** No number may be written into a function, a
widget or a constant. When a number is needed, read it from
`wish_categories`, `call_entitlements`, `subscription_tiers`,
`call_policy` or `payment_settings`. Scripts that set values
should locate their target by relationship (level order, kind,
`call_kind`) rather than by a literal id, so a late change to the
tier list does not silently misfile them.

## V. HAS MOVED TO PART 7

Part 6 reached its 18 KB ceiling. The 7 Oct live call test, the
cal.com defect and the owner's push-notification instructions are
in **IVORY_HANDOVER_7.md**.

<!-- END OF FILE - IVORY_HANDOVER_6.md -->
