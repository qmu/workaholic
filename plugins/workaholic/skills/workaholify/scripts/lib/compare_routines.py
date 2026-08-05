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
    """The DISPLAY form: what a reader sees, trimmed of noise but otherwise as given."""
    return (u or "").rstrip("/").removesuffix(".git")


def canon_url(u):
    """The COMPARISON form: `host/owner/name`, host lowercased, userinfo and scheme gone.

    A remote names one repository in several interchangeable spellings --
    `git@github.com:qmu/workaholic`, `ssh://git@github.com/qmu/workaholic` and
    `https://github.com/qmu/workaholic`, each with or without `.git` and a trailing
    slash. `norm_url` reduced only the last two, so an SSH-form checkout never matched
    an https-form routine and `/setup-routines` reported ZERO routines and every
    template missing for a repository with three live, working ones (measured
    2026-08-05). An identity comparison must be canonical before it is trusted to say
    "nothing exists"; the workaround was passing the https form by hand.

    THE HOST KEEPS ITS PORT AND THE PATH KEEPS ITS CASE. Only the host is lowercased,
    because `github.com/Qmu/Workaholic` and `github.com/qmu/workaholic` are the same
    host but not provably the same repository path, and folding them would trade one
    confident wrong answer for another. A proxy URL such as
    `http://local_proxy@127.0.0.1:41729/git/qmu/workaholic` therefore stays DISTINCT
    from the github.com form -- deliberately: whether a rewritten remote should resolve
    back to its canonical origin is a separate question about `resolve-target.sh`, and
    silently equating them here would prejudge it.
    """
    s = (u or "").strip()
    if not s:
        return ""
    # A scheme tells us any later colon is a port, not the scp-like `host:path`
    # separator -- so the two forms cannot be disambiguated after the fact.
    had_scheme = "://" in s
    if had_scheme:
        s = s.split("://", 1)[1]
    if "@" in s:
        s = s.split("@", 1)[1]
    if not had_scheme and ":" in s:
        host, _, path = s.partition(":")
        s = f"{host}/{path}"
    s = s.rstrip("/").removesuffix(".git").rstrip("/")
    host, sep, path = s.partition("/")
    return f"{host.lower()}{sep}{path}"


def ccr(t):
    return (t.get("job_config") or {}).get("ccr") or {}


def sources_of(t):
    ctx = ccr(t).get("session_context") or {}
    return [norm_url((s.get("git_repository") or {}).get("url")) for s in ctx.get("sources") or []]


def canon_sources_of(t):
    """`sources_of` reduced for comparison. Membership is decided here; what gets
    REPORTED is always the display form, so a caller's own spelling survives."""
    return [canon_url(s) for s in sources_of(t)]


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
    repo_key = canon_url(repo)
    mine = [t for t in items if repo_key in canon_sources_of(t)]
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
        # The LIVE facts ride along beside the drift: a reader that only learns "this
        # routine differs in `schedule`" still cannot tell a developer what the routine
        # actually does today. `list-routines.sh` presents these; nothing else reads the
        # raw API response, so surfacing them here keeps the API shape in one file.
        present.append({
            "id": tpl["id"], "name": want["name"], "trigger_id": hit.get("id"), "drift": d,
            "trigger": want["trigger"], "schedule": hit.get("cron_expression") or "",
            "enabled": bool(hit.get("enabled", True)), "target_repo": repo,
        })

    unknown = [
        {
            "name": t.get("name"), "trigger_id": t.get("id"),
            "schedule": t.get("cron_expression") or "",
            "enabled": bool(t.get("enabled", True)), "target_repo": repo,
        }
        for t in mine
        if t.get("id") not in matched
    ]

    # ---- every OTHER repository already carrying a workaholic routine: drift only ----
    others = {}
    for t in items:
        srcs = sources_of(t)
        target = srcs[0] if srcs else ""
        target_key = canon_url(target)
        if not target or target_key == repo_key:
            continue
        name = (t.get("name") or "").strip()
        for tpl in templates:
            want = render(tpl["id"], target)
            if name != want["name"]:
                continue
            d = drift_of(t, want)
            drifted_total += 1 if d else 0
            # Grouped by the CANONICAL key so two routines spelling the same repository
            # differently land in one group; the first spelling seen is what is reported.
            others.setdefault(
                target_key,
                {"repo": target, "repo_name": target.rstrip("/").split("/")[-1], "present": []},
            )
            others[target_key]["present"].append(
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
