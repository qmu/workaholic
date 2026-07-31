"""Compare live Claude Code Web routines against the shipped templates.

Driven by ``compare-routines.sh``; see that script's header for the model and for why the
comparison spans every repository rather than only the current one.

It lives as its own file rather than a heredoc inside the shell script because the
comparison is genuinely JSON-shaped on both sides, and a heredoc nested inside the
script's own heredoc is the kind of quoting that breaks silently later.
"""

import json
import subprocess
import sys


def norm_url(u):
    return (u or "").rstrip("/").removesuffix(".git")


def ccr(t):
    return (t.get("job_config") or {}).get("ccr") or {}


def sources_of(t):
    ctx = ccr(t).get("session_context") or {}
    return [norm_url((s.get("git_repository") or {}).get("url")) for s in ctx.get("sources") or []]


def live_prompt(t):
    evs = ccr(t).get("events") or []
    if not evs:
        return ""
    return ((evs[0].get("data") or {}).get("message") or {}).get("content") or ""


def live_model(t):
    return (ccr(t).get("session_context") or {}).get("model") or ""


def has_slack(t):
    return any((c.get("name") or "").lower() == "slack" for c in t.get("mcp_connections") or [])


def main():
    live_path, repo, repo_name, script_dir, templates_json = sys.argv[1:6]

    try:
        with open(live_path) as fh:
            live = json.load(fh)
    except Exception as exc:  # noqa: BLE001 - the reason must reach the caller verbatim
        print(json.dumps({"error": "unparseable_live_input", "detail": str(exc)}))
        return 1

    items = live.get("data", live if isinstance(live, list) else [])
    templates = json.loads(templates_json)["templates"]

    cache = {}

    def render(tid, target):
        key = (tid, target)
        if key not in cache:
            out = subprocess.run(
                ["sh", f"{script_dir}/render-routine.sh", tid, target],
                capture_output=True, text=True,
            )
            cache[key] = json.loads(out.stdout)
        return cache[key]

    def drift_of(hit, want):
        d = []
        if live_prompt(hit).strip() != want["prompt"].strip():
            d.append("prompt")
        if live_model(hit) != want["model"]:
            d.append(f"model ({live_model(hit) or 'unset'} != {want['model']})")
        if (hit.get("cron_expression") or "") != want["cron_expression"]:
            d.append(
                f"schedule ({hit.get('cron_expression') or 'none'} "
                f"!= {want['cron_expression'] or 'none'})"
            )
        if not hit.get("enabled", True):
            d.append("disabled")
        # Every template posts to Slack. A routine without the connector runs, does its
        # work, and fails silently at the last step -- drift, and the expensive kind.
        if not has_slack(hit):
            d.append("slack connector missing")
        return d

    # The Slack connector is an ACCOUNT-level fact, discovered from whatever routine
    # already carries one: a new routine needs its uuid/url, and this is where they live.
    slack = {"present": False}
    for t in items:
        for c in t.get("mcp_connections") or []:
            if (c.get("name") or "").lower() == "slack":
                slack = {
                    "present": True,
                    "connector_uuid": c.get("connector_uuid"),
                    "name": c.get("name"),
                    "url": c.get("url"),
                }
                break
        if slack["present"]:
            break

    drifted_total = 0

    # ---- this repository: missing AND drifted ----
    mine = [t for t in items if repo in sources_of(t)]
    missing, present, matched = [], [], set()
    for tpl in templates:
        want = render(tpl["id"], repo)
        hit = next((t for t in mine if (t.get("name") or "").strip() == want["name"]), None)
        if hit is None:
            missing.append({"id": tpl["id"], "name": want["name"], "trigger": want["trigger"]})
            continue
        matched.add(hit.get("id"))
        d = drift_of(hit, want)
        drifted_total += 1 if d else 0
        present.append(
            {"id": tpl["id"], "name": want["name"], "trigger_id": hit.get("id"), "drift": d}
        )

    unknown = [
        {"name": t.get("name"), "trigger_id": t.get("id")}
        for t in mine
        if t.get("id") not in matched
    ]

    # ---- every OTHER repository already carrying a workaholic routine: drift only ----
    others = {}
    for t in items:
        srcs = sources_of(t)
        target = srcs[0] if srcs else ""
        if not target or target == repo:
            continue
        name = (t.get("name") or "").strip()
        for tpl in templates:
            want = render(tpl["id"], target)
            if name != want["name"]:
                continue
            d = drift_of(t, want)
            drifted_total += 1 if d else 0
            others.setdefault(
                target,
                {"repo": target, "repo_name": target.rstrip("/").split("/")[-1], "present": []},
            )
            others[target]["present"].append(
                {"id": tpl["id"], "name": name, "trigger_id": t.get("id"), "drift": d}
            )
            break

    print(json.dumps({
        "repo": repo,
        "repo_name": repo_name,
        "total_live": len(items),
        "drifted_total": drifted_total,
        "slack_connector": slack,
        "this_repo": {"missing": missing, "present": present, "unknown": unknown},
        "other_repos": sorted(others.values(), key=lambda x: x["repo"]),
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
