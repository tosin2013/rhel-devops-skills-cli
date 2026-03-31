---
title: "ADR-008: Skill Update Strategy"
nav_order: 8
parent: Architecture Decision Records
---

# ADR-008: Skill Update Strategy

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [RHEL and macOS Compatibility](../research/rhel-bash-and-tooling-compatibility.md)

## Context and Problem Statement

Skills embed documentation fetched from source repositories (AgnosticD, Field-Sourced Content Template, Patternizer) into their `references/` directory at install time. These source repositories are actively maintained and documentation changes over time. Users need a way to detect and apply documentation updates without manually tracking upstream commits.

How should the installer detect and apply updates when source repositories change?

## Decision Drivers

* Source repos are actively maintained; documentation may change weekly
* Users should not have to manually check for updates
* Auto-checking must not block or slow down normal operations significantly
* Network may not always be available (offline environments, air-gapped RHEL)
* The JSON registry already stores `docs_commit_hash` per skill (ADR-006)
* Updates should be non-destructive -- backup before replacing

## Considered Options

1. **Manual-only updates** -- User must explicitly run `--update` or `--check-updates`
2. **Auto-check on every run + manual update** -- Check for updates automatically, apply only on explicit request
3. **Scheduled cron job** -- Background periodic checks via cron/systemd timer
4. **GitHub webhook + Actions** -- Server-side: when source repo changes, a workflow PRs updated docs into this repo

## Decision Outcome

Chosen option: **"Auto-check on every run + manual update"**, because it keeps users informed without requiring action, fails silently when offline, and leverages the existing registry `docs_commit_hash` field for comparison.

### Auto-Check Mechanism

On every `install.sh` invocation, if `auto_check_updates` is `true` in the registry:

```bash
check_updates_background() {
    local skill_name="$1"
    local stored_hash
    stored_hash="$(registry_get_skill "$skill_name" "docs_commit_hash")"
    local source_repo
    source_repo="$(get_skill_config "$skill_name" "source_repo")"
    local branch
    branch="$(get_skill_config "$skill_name" "branch")"

    local remote_hash
    remote_hash="$(git ls-remote "$source_repo" "refs/heads/$branch" 2>/dev/null | cut -f1)"

    if [[ -n "$remote_hash" && "$remote_hash" != "$stored_hash" ]]; then
        info "Update available for '$skill_name' (run: ./install.sh --update $skill_name)"
    fi
}
```

* Uses `git ls-remote` (single network call, no clone) to fetch the latest commit hash
* Compares against `docs_commit_hash` stored in the registry
* Displays a one-line notification if an update is available
* Fails silently if network is unavailable (the `2>/dev/null` redirect)
* Adds ~1-2 seconds per installed skill when auto-check is enabled

### Manual Update Flow

```
1. User runs: ./install.sh --update <skill>
2. Validate skill is installed (check registry)
3. Fetch latest commit hash from source repo
4. Compare with stored hash -- if identical, inform user and exit
5. Backup current references/ to ~/.rhel-devops-skills/backups/<skill>-<date>/
6. Fetch latest documentation from source repo
7. Replace references/ with new content
8. Update registry: docs_commit_hash, docs_fetched_date
9. Display update summary
```

### Check-Updates Flow (read-only)

```
1. User runs: ./install.sh --check-updates
2. For each installed skill in registry:
   a. Fetch latest commit hash via git ls-remote
   b. Compare with stored docs_commit_hash
   c. Display: skill name, current hash (short), remote hash (short), status
3. Display summary: N skills up-to-date, M skills with updates available
```

### Registry Fields Used

```json
{
  "auto_check_updates": true,
  "installed_skills": [
    {
      "name": "agnosticd",
      "docs_commit_hash": "abc123def456",
      "docs_fetched_date": "2026-03-31T10:30:00Z",
      "source_repo": "https://github.com/tosin2013/agnosticd-v2"
    }
  ]
}
```

### Positive Consequences

* Users are proactively informed about available updates
* No action required unless the user wants to update
* Fails gracefully when offline -- no error, no blocking
* Leverages existing registry fields (no schema change needed)
* `git ls-remote` is lightweight (no data transfer beyond hash)
* Backup before update prevents data loss

### Negative Consequences

* Auto-check adds ~1-2 seconds per skill to every run
* Requires network access for auto-check (may not work in air-gapped environments)
* `git ls-remote` compares branch HEAD, not specific documentation paths -- may trigger false positives if non-doc files changed
* Users in strictly offline environments should set `auto_check_updates: false`

## Links

* [GitHub API - Get a commit](https://docs.github.com/en/rest/commits/commits#get-a-commit)
* [git ls-remote documentation](https://git-scm.com/docs/git-ls-remote)
* Related: [ADR-003](003-documentation-embedding-strategy.md) (references/ structure), [ADR-006](006-shell-installer-architecture.md) (registry format)
