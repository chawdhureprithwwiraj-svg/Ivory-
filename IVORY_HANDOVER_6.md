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

<!-- END OF FILE - IVORY_HANDOVER_6.md -->
