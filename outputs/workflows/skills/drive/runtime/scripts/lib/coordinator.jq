# A native host supplies observations; this reducer owns control, receipts and cadence.
def integer: type == "number" and floor == . and . >= 0;
def fail($why): error($why);
def active: .state == "reserved" or .state == "launching" or .state == "running" or .state == "unknown";
def roles: ["implement", "propose", "moderate"];
# A continuation is what carries the loop after a turn ends (2026-09-11, issue #1151): the
# interruptible parent the turn returns to, or the same-chat schedule that fires the next tick.
# It is recorded at `start`, `resume` or `continued` and read at every event as `resumed`:
# `control == running` alone is never a resumed loop.
def valid_continuation:
  type == "object" and (.kind == "interruptible_parent" or .kind == "same_chat_schedule") and
  (.id|type == "string" and length > 0) and (.next_due|integer);
def valid_result:
  type == "object" and (.executed|type == "boolean") and
  (.outcome|type == "string" and length > 0) and (.reason|type == "string") and
  (.report|type == "string");
def finish_times:
  [.workers[] | select(.state == "completed")] | group_by(.role) |
  map({key:.[0].role,value:(map(.finished_at)|max)}) | from_entries;

.input as $e | .state as $s |
if ($e.now|integer|not) then fail("now must be epoch seconds") else . end |
if $e.event == "start" then
  if $s != null then {state:$s,changed:false,reason:"already_started"}
  elif ($e.session_id|type != "string" or length == 0) then fail("session_id required")
  elif $e.continuation != null and ($e.continuation|valid_continuation|not) then fail("invalid continuation")
  else {state:{mode:"running",anchor:$e.now,session_id:$e.session_id,workers:{},
    max_workers:($e.max_workers // 2),fanout:($e.fanout // 1),
    continuation:($e.continuation // null)},changed:true,reason:"started"} end
elif $s == null then fail("instance not started")
elif $e.event == "hold" or $e.event == "resume" or $e.event == "stop" then
  if $e.explicit != true then fail("control requires explicit human instruction")
  elif $s.mode == "stopped" then {state:$s,changed:false,reason:"stopped"}
  elif $e.event == "resume" and $e.continuation != null and ($e.continuation|valid_continuation|not) then fail("invalid continuation")
  else {state:($s | .mode=(if $e.event == "hold" then "held" elif $e.event == "stop" then "stopped" else "running" end)
    | if $e.event == "resume" and $e.continuation != null then .continuation=$e.continuation else . end),
    changed:true,reason:$e.event} end
elif $e.event == "continued" then
  if ($e.continuation|valid_continuation|not) then fail("continuation required")
  elif $s.mode == "stopped" then {state:$s,changed:false,reason:"stopped"}
  else {state:($s|.continuation=$e.continuation),changed:true,reason:"continued"} end
elif $e.event == "reserve" then
  if $s.mode != "running" then {state:$s,changed:false,reason:$s.mode}
  elif (($e.id|type) != "string" or ($e.id|test("^[A-Za-z0-9][A-Za-z0-9._-]*$")|not)) then fail("invalid receipt id")
  elif (roles|index($e.role)) == null then fail("invalid role")
  elif $s.workers[$e.id] != null then {state:$s,changed:false,reason:"receipt_exists"}
  elif $e.workers_readable != true then {state:$s,changed:false,reason:"capacity_unreadable"}
  elif ($e.available_capacity|integer|not) then fail("invalid available_capacity")
  elif $e.available_capacity == 0 or ([$s.workers[]|select(active)]|length) >= $s.max_workers then
    {state:$s,changed:false,reason:"capacity_exhausted"}
  elif $e.role == "implement" and $e.formation_pending != false then
    {state:$s,changed:false,reason:"mission_formation_pending"}
  elif $e.role == "implement" and any($s.workers[] | select(active and .role == "implement");
    (.target.tickets // []) as $taken | any(($e.target.tickets // [])[]; . as $ticket | $taken | index($ticket))) then
    {state:$s,changed:false,reason:"target_overlap"}
  elif ([$s.workers[]|select(active and .role == $e.role)]|length) >=
    (if $e.role == "implement" then $s.fanout else 1 end) then
    {state:$s,changed:false,reason:"role_running"}
  else {state:($s|.workers[$e.id]={id:$e.id,role:$e.role,state:"reserved",reserved_at:$e.now,
    child_id:null,target:($e.target // null),reported:false}),changed:true,reason:"reserved"} end
elif $e.event == "launch" then
  if $s.mode != "running" then {state:$s,changed:false,reason:$s.mode}
  elif $s.workers[$e.id].state != "reserved" then {state:$s,changed:false,reason:"receipt_not_reserved"}
  else {state:($s|.workers[$e.id].state="launching"),changed:true,reason:"launching"} end
elif $e.event == "started" or $e.event == "finish" or $e.event == "reported" or $e.event == "unknown" or $e.event == "cancelled" then
  $s.workers[$e.id] as $w |
  if $w == null then fail("unknown receipt")
  elif $e.event == "cancelled" then
    if $e.confirmed != true or ($e.child_id|type != "string" or length == 0) or $e.child_id != $w.child_id then
      {state:$s,changed:false,reason:"cancellation_unverified"}
    elif $w.state == "completed" then {state:$s,changed:false,reason:"already_completed"}
    elif $w.state == "cancelled" then {state:$s,changed:false,reason:"already_cancelled"}
    else {state:($s|.workers[$e.id] += {state:"cancelled",cancelled_at:$e.now}),changed:true,reason:"cancelled"} end
  elif $e.event == "started" then
    if ($e.child_id|type != "string" or length == 0) then fail("child_id required")
    elif $w.state != "reserved" and $w.state != "launching" then {state:$s,changed:false,reason:"already_started"}
    else {state:($s|.workers[$e.id].state="running"|.workers[$e.id].child_id=$e.child_id),changed:true,reason:"started"} end
  elif $e.event == "unknown" then
    if $w.state == "completed" or $w.state == "cancelled" then {state:$s,changed:false,reason:("already_"+$w.state)}
    else {state:($s|.workers[$e.id].state="unknown"),changed:true,reason:"result_unreadable"} end
  elif $e.event == "reported" then
    if $w.state != "completed" then fail("no completed result")
    else {state:($s|.workers[$e.id].reported=true),changed:($w.reported != true),reason:"reported"} end
  elif ($e.result|valid_result|not) or $e.terminal != true then
    {state:($s|if (.workers[$e.id]|active) then .workers[$e.id].state="unknown" else . end),
      changed:($w|active),reason:"result_unreadable"}
  elif $w.state == "completed" then
    {state:$s,changed:false,reason:(if $w.result == $e.result then "duplicate_result" else "conflicting_result" end)}
  else {state:($s|.workers[$e.id] += {state:"completed",finished_at:$e.now,result:$e.result,
    process_exit:($e.process_exit // null)}),changed:true,reason:"completed"} end
elif $e.event == "tick" then {state:$s,changed:false,reason:$s.mode}
else fail("unknown coordinator event") end |
if (.state.max_workers|integer|not) or .state.max_workers < 1 or
   (.state.fanout|integer|not) or .state.fanout < 1 then fail("worker limits must be positive integers") else . end |
.state as $next |
($next|finish_times) as $finished |
($next.continuation // null) as $continuation |
(if $next.mode != "running" then $next.mode
 elif $continuation == null then "continuation_unproved"
 elif $continuation.next_due < $e.now then "continuation_lapsed"
 else "" end) as $not_resumed |
. + {control:$next.mode,anchor:$next.anchor,
  resumed:($not_resumed == ""),resumed_reason:$not_resumed,continuation:$continuation,
  cancel_schedule:($next.mode == "stopped"),
  cancel_children:(if $next.mode == "stopped" then [$next.workers[]|select(active)|{id,child_id}] else [] end),
  completed:(if $next.mode == "held" then [] else [$next.workers[]|select(.state == "completed" and .reported != true)] end),
  live:[$next.workers[]|select(active)|{id,role,child_id,state,target}],
  cancelled:[$next.workers[]|select(.state == "cancelled")|{id,role,child_id,cancelled_at}],
  due:(if $next.mode != "running" then [] else
    [roles[] as $role |
      (if $role == "implement" then 300 elif $role == "propose" then 900 else 1800 end) as $cadence |
      select(($finished[$role] // 0) + $cadence <= $e.now) |
      {role:$role,due_at:(($finished[$role] // 0)+$cadence)}] | sort_by(.due_at,.role) end)}
