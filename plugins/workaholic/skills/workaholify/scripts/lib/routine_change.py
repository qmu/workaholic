"""Plan and authorize a change to one scheduled routine.

Driven by ``plan-routine-change.sh`` and ``authorize-routine-change.sh``; the model and
the reasons live in those two headers. This file holds the part that must not be allowed
to disagree with itself: the canonical form of a routine change, and the digest over it.

ONE FUNCTION COMPUTES THE DIGEST, AND BOTH SIDES CALL IT. A planner and an authorizer
free to canonicalise differently would be a gate that passes everything, which is worse
than no gate because it reads as one.
"""

import hashlib
import json
import os
import subprocess
import sys

DELETION_URL = "https://claude.ai/code/routines"

# The fields a human can verify by eye, and therefore the only fields the confirmation is
# allowed to be about. Account plumbing (environment id, connector uuid) is deliberately
# excluded: nobody reads a uuid to decide whether a routine should exist, and folding it
# in would make the digest change for reasons the developer cannot see.
CONTENT_FIELDS = ("action", "repo", "name", "trigger", "cron_expression", "model",
                  "enabled", "prompt")


def digest(plan):
    canon = "\n".join(
        json.dumps(plan.get(f) if f != "enabled" else bool(plan.get("enabled")))
        for f in CONTENT_FIELDS
    )
    return "sha256:" + hashlib.sha256(canon.encode("utf-8")).hexdigest()


def emit(obj):
    print(json.dumps(obj))
    return 0


def noop(action, template, repo, reason, detail, **extra):
    """A refusal or a nothing-to-do, and NEVER a silent success.

    It carries no ``confirm_digest``, so there is nothing for the authorizer to accept:
    a plan that decided there is nothing to do cannot be turned into an apply by a caller
    that did not read the reason.
    """
    out = {"action": action, "template": template, "repo": repo,
           "noop": True, "reason": reason, "detail": detail}
    out.update(extra)
    return emit(out)


def render(script_dir, template, repo):
    out = subprocess.run(
        ["sh", os.path.join(script_dir, "render-routine.sh"), template, repo],
        capture_output=True, text=True,
    )
    return json.loads(out.stdout)


def compare(script_dir, repo, live_raw):
    out = subprocess.run(
        ["sh", os.path.join(script_dir, "compare-routines.sh"), repo],
        input=live_raw, capture_output=True, text=True,
    )
    return json.loads(out.stdout)


def live_entry(live, trigger_id):
    items = live.get("data", live if isinstance(live, list) else [])
    return next((t for t in items if t.get("id") == trigger_id), {})


def live_prompt(entry):
    evs = ((entry.get("job_config") or {}).get("ccr") or {}).get("events") or []
    if not evs:
        return ""
    return ((evs[0].get("data") or {}).get("message") or {}).get("content") or ""


def plan(argv):
    action, template, repo, live_path, script_dir, enable = argv
    enable = enable == "1"

    if action not in ("create", "refresh", "remove"):
        return emit({"noop": True, "reason": "unknown_action", "action": action,
                     "detail": "actions are create, refresh, remove"})

    want = render(script_dir, template, repo)
    if want.get("error"):
        return noop(action, template, repo, "unknown_template",
                    "no template with that id is shipped by this plugin")

    try:
        with open(live_path) as fh:
            live_raw = fh.read()
        live = json.loads(live_raw)
    except Exception as exc:  # noqa: BLE001
        # A change planned against a routines list nobody could read would be a change
        # planned blind. Refuse; do not assume the routine is absent and offer to create it.
        return noop(action, template, repo, "no_live_input",
                    "the live routines could not be read (%s); nothing can be planned "
                    "against an account that was never asked" % exc)

    cmp_json = compare(script_dir, repo, live_raw)
    hit = next((p for p in cmp_json["this_repo"]["present"] if p["id"] == template), None)

    if action == "create":
        if hit is not None:
            return noop(action, template, repo, "already_exists",
                        "a routine of this name already points at this repository; "
                        "refresh it instead of creating a second one",
                        trigger_id=hit["trigger_id"])
        body = {"action": "create", "repo": repo, "name": want["name"],
                "trigger": want["trigger"], "cron_expression": want["cron_expression"],
                "model": want["model"], "enabled": True, "prompt": want["prompt"],
                "trigger_id": None}

    elif action == "refresh":
        if hit is None:
            return noop(action, template, repo, "not_present",
                        "no live routine matches this template for this repository; "
                        "create it instead")
        if not hit["enabled"] and not enable:
            # Removal is disabling (there is no delete), so a disabled routine is one
            # somebody switched OFF. Quietly switching it back on under the name
            # "refresh" would undo a deliberate act without anyone deciding to.
            return noop(action, template, repo, "disabled_routine",
                        "this routine is disabled — refreshing it would re-enable "
                        "something that was deliberately switched off; pass --enable to "
                        "say that is what you mean",
                        trigger_id=hit["trigger_id"])
        if not hit["drift"]:
            # THE IDEMPOTENCE THE TICKET ASKED FOR, and it reports itself rather than
            # sending an update that changes nothing.
            return noop(action, template, repo, "no_drift",
                        "the live routine already matches the template in every compared "
                        "field; nothing to refresh",
                        trigger_id=hit["trigger_id"])
        body = {"action": "refresh", "repo": repo, "name": want["name"],
                "trigger": want["trigger"], "cron_expression": want["cron_expression"],
                "model": want["model"], "enabled": True, "prompt": want["prompt"],
                "trigger_id": hit["trigger_id"], "resolves": hit["drift"]}

    else:  # remove
        if hit is None:
            return noop(action, template, repo, "not_present",
                        "no live routine matches this template for this repository",
                        manual_deletion_url=DELETION_URL)
        if not hit["enabled"]:
            return noop(action, template, repo, "already_disabled",
                        "this routine is already disabled; the routines API has no "
                        "delete, so removing the entry itself is a human act",
                        trigger_id=hit["trigger_id"], manual_deletion_url=DELETION_URL)
        entry = live_entry(live, hit["trigger_id"])
        # The prompt shown for a removal is the LIVE one, not the template's: the developer
        # is switching off what is actually there, which may have drifted from the template.
        body = {"action": "remove", "repo": repo, "name": hit["name"],
                "trigger": hit["trigger"], "cron_expression": hit["schedule"],
                "model": want["model"], "enabled": False, "prompt": live_prompt(entry),
                "trigger_id": hit["trigger_id"], "manual_deletion_url": DELETION_URL,
                "removal_means": "disable — the routines API has no delete; deleting the "
                                 "entry is a human act at " + DELETION_URL}

    body["template"] = template
    body["noop"] = False
    body["confirm_digest"] = digest(body)
    return emit(body)


def authorize(argv):
    plan_path, given = argv

    try:
        with open(plan_path) as fh:
            p = json.load(fh)
    except Exception as exc:  # noqa: BLE001
        return emit({"authorized": False, "reason": "unreadable_plan", "detail": str(exc)})

    if p.get("noop"):
        return emit({"authorized": False, "reason": "noop_plan",
                     "detail": "this plan decided there is nothing to do (%s)"
                               % p.get("reason", "no reason given")})
    if not p.get("confirm_digest"):
        return emit({"authorized": False, "reason": "no_digest",
                     "detail": "this plan carries no confirmation digest"})

    recomputed = digest(p)
    if recomputed != p["confirm_digest"]:
        # The plan file changed after it was rendered: what a developer was shown and what
        # is about to be sent are no longer the same thing.
        return emit({"authorized": False, "reason": "plan_tampered",
                     "detail": "the plan's content no longer hashes to its own digest"})
    if given != recomputed:
        # A yes to one body cannot authorize another, and one yes cannot cover a batch.
        return emit({"authorized": False, "reason": "digest_mismatch",
                     "detail": "the confirmed digest does not match this plan; a "
                               "confirmation is for exactly one routine body"})

    return emit({
        "authorized": True,
        "action": p["action"],
        "template": p.get("template"),
        "trigger_id": p.get("trigger_id"),
        "apply": {k: p[k] for k in ("name", "trigger", "cron_expression", "model",
                                    "enabled", "prompt")},
    })


if __name__ == "__main__":
    mode = sys.argv[1]
    sys.exit(plan(sys.argv[2:]) if mode == "plan" else authorize(sys.argv[2:]))
