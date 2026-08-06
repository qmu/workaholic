"""Present what runs against one repository, or say honestly that it could not be checked.

Driven by ``list-routines.sh``; see that script's header for the model.

THE WHOLE POINT IS THE FIRST HALF OF THIS FILE. Deciding that the live response is an
ANSWER — rather than assuming it is one and reporting an empty list — is the reason this
exists as a separate reader instead of a formatting pass over ``compare-routines.sh``.
Only a JSON list, or an object carrying a ``data`` list, counts as having looked. Every
other input (absent, empty, unparseable, an API error object, an unrecognised shape) is
``checked: false`` with a named reason and NO ``routines`` key at all, so a caller cannot
misread "I could not look" as "nothing runs here".
"""

import json
import os
import subprocess
import sys


def unchecked(repo, repo_name, reason, detail):
    print(json.dumps({
        "repo": repo, "repo_name": repo_name,
        "checked": False, "reason": reason, "detail": detail,
    }))
    return 0


def template_set_version(script_dir):
    """The plugin version that provides the templates this comparison used.

    It is NOT the version that created any live routine — the API records no such thing,
    and inventing one would be the kind of confident wrong answer this command exists to
    avoid. What a reader gets is: these templates, at this version, and per routine
    whether the live one still matches them.
    """
    path = os.path.join(script_dir, "..", "..", "..", ".claude-plugin", "plugin.json")
    try:
        with open(path) as fh:
            return json.load(fh).get("version")
    except Exception:  # noqa: BLE001 - a missing manifest is not a reason to fail the read
        return None


def main():
    live_path, repo, repo_name, script_dir = sys.argv[1:5]

    try:
        with open(live_path) as fh:
            raw = fh.read()
    except Exception as exc:  # noqa: BLE001
        return unchecked(repo, repo_name, "unreadable_live_input", str(exc))

    if not raw.strip():
        return unchecked(
            repo, repo_name, "no_live_input",
            "no routines response was supplied; the account was never asked",
        )

    try:
        live = json.loads(raw)
    except Exception as exc:  # noqa: BLE001
        return unchecked(repo, repo_name, "unparseable_live_input", str(exc))

    if isinstance(live, dict) and live.get("error"):
        return unchecked(
            repo, repo_name, "api_error",
            "the routines API answered with an error: %s" % json.dumps(live["error"]),
        )

    if isinstance(live, list):
        items = live
    elif isinstance(live, dict) and isinstance(live.get("data"), list):
        items = live["data"]
    else:
        # An object with no `data` list is not an empty account — it is a response this
        # reader does not recognise, and calling it empty would be a fabrication.
        return unchecked(
            repo, repo_name, "unrecognised_live_shape",
            "the response carried no `data` list; this is NOT evidence that no routines exist",
        )

    cmp_out = subprocess.run(
        ["sh", os.path.join(script_dir, "compare-routines.sh"), repo],
        input=json.dumps({"data": items}), capture_output=True, text=True,
    )
    try:
        cmp_json = json.loads(cmp_out.stdout)
    except Exception as exc:  # noqa: BLE001
        return unchecked(
            repo, repo_name, "comparison_failed",
            "%s%s" % (exc, (" / " + cmp_out.stderr.strip()) if cmp_out.stderr.strip() else ""),
        )

    mine = cmp_json["this_repo"]
    routines = []
    for p in mine["present"]:
        routines.append({
            "name": p["name"],
            "template": p["id"],
            "status": "drifted" if p["drift"] else "current",
            # `trigger` is what the TEMPLATE declares, not what the account is wired to:
            # the API exposes no trigger field, so live wiring is unreadable here. The
            # qualifier travels in the data so no renderer can print the value without
            # it (measured 2026-08-06: a [Propose] wired to fire on merges read as
            # `github-issue-assigned`, and only a manual UI check showed the mismatch).
            "trigger": p["trigger"],
            "trigger_source": "template_declared",
            "schedule": p["schedule"] or None,
            "target_repo": p["target_repo"],
            "enabled": p["enabled"],
            "trigger_id": p["trigger_id"],
            "drift": p["drift"],
        })
    for u in mine["unknown"]:
        # A routine matching no template is somebody's deliberate one-off, listed so that
        # nothing is invisible. It is never a problem and never a deletion proposal.
        routines.append({
            "name": u["name"],
            "template": None,
            "status": "unknown",
            # A record with no schedule is not "event-driven": the API has no event
            # subscription at all, so such a routine simply waits to be invoked
            # (workaholify SKILL, *What a routine can be triggered by*).
            "trigger": "cron" if u["schedule"] else "invoked",
            "trigger_source": "template_declared",
            "schedule": u["schedule"] or None,
            "target_repo": u["target_repo"],
            "enabled": u["enabled"],
            "trigger_id": u["trigger_id"],
            "drift": [],
            "note": "matches no shipped template — a deliberate one-off, not a problem",
        })

    elsewhere_drifted = sum(
        1 for r in cmp_json["other_repos"] for p in r["present"] if p["drift"]
    )

    print(json.dumps({
        "repo": repo,
        "repo_name": repo_name,
        "checked": True,
        "trigger_readable": False,
        "template_set_version": template_set_version(script_dir),
        "total_live": cmp_json["total_live"],
        "routines": routines,
        "missing": mine["missing"],
        "slack_connector": cmp_json["slack_connector"],
        "elsewhere": {"repos": len(cmp_json["other_repos"]), "drifted": elsewhere_drifted},
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
