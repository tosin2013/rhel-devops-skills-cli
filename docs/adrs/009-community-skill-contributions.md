---
title: "ADR-009: Community Skill Contributions"
nav_order: 9
parent: Architecture Decision Records
---

# ADR-009: Community Skill Contributions via GitHub Issues

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team

## Context and Problem Statement

The initial release ships three built-in skills (agnosticd, field-sourced-content, patternizer). As the project grows, developers working with other RHEL DevOps tools will want to contribute new skills. A clear, quality-controlled process is needed for accepting community-contributed skills.

How should new skills be proposed, reviewed, and added to the repository?

## Decision Drivers

* Skills must follow the Agent Skills standard (ADR-001) and references/ structure (ADR-003)
* Documentation paths must actually exist in the source repository
* Quality and consistency are more important than contribution velocity
* Contributors may not be familiar with the SKILL.md format or the installer's fetch-docs configuration
* Maintainers need enough information to build and test the skill
* The process should be accessible to non-developer contributors (e.g., DevOps engineers who know the tool but don't want to write SKILL.md)

## Considered Options

1. **Self-service PRs** -- Contributors build the full `skills/<name>/` directory and submit a PR
2. **GitHub Issue template intake** -- Contributors describe the skill via a structured issue; maintainers build it
3. **External registry** -- Contributors host their own skill repo and register it in a manifest
4. **Both: issue template + optional self-service PR** -- Issue template is the default; experienced contributors can submit PRs directly

## Decision Outcome

Chosen option: **"GitHub Issue template intake with maintainer build"**, because it lowers the barrier for contributors, ensures consistent quality, and gives maintainers control over the fetch-docs configuration and testing.

### Contribution Process

```
1. Developer opens GitHub Issue using "New Skill Request" template
2. Template collects:
   - Skill name and description
   - Source repository URL and default branch
   - Documentation file paths to fetch
   - Suggested "When to Use" triggers
   - Optional: Cursor rule globs/patterns
   - Optional: related tools or dependencies
3. Maintainer reviews the issue:
   - Validates source repo exists and is accessible
   - Confirms documentation paths are correct
   - Assesses whether the skill is a good fit for the project
4. Maintainer (or assigned contributor) builds:
   - skills/<name>/SKILL.md (following ADR-001)
   - skills/<name>/references/REFERENCE.md (following ADR-003)
   - Optional: skills/<name>/rules/<name>.mdc (following ADR-005)
   - Updates skill config in fetch-docs for the new skill
5. Maintainer submits PR referencing the issue
6. PR is validated:
   - [ ] SKILL.md has valid YAML frontmatter with name and description
   - [ ] references/REFERENCE.md lists all documentation files
   - [ ] Skill installs successfully to ~/.claude/skills/ and ~/.cursor/skills-cursor/
   - [ ] ShellCheck passes on any scripts/
   - [ ] CI tests pass
7. PR merged -> skill available in next release
```

### Issue Template

The structured YAML issue form (`.github/ISSUE_TEMPLATE/new-skill-request.yml`) collects all information needed to build a skill without requiring the contributor to know the SKILL.md format.

### Why Not Self-Service PRs?

* Contributors may not know the SKILL.md format, references/ structure, or fetch-docs configuration
* Inconsistent quality if contributors skip validation steps
* Documentation paths may be incorrect or point to non-existent files
* Maintainers need to test the skill against both Claude Code and Cursor
* A curated approach builds trust in the skill catalog

Experienced contributors who are familiar with the format are welcome to submit PRs directly, but the issue template is the recommended and documented path.

### Positive Consequences

* Low barrier to entry -- contributors just fill out a form
* Consistent quality -- maintainers control the build process
* All skills follow the same format (ADR-001, ADR-003, ADR-004)
* Maintainers can configure fetch-docs correctly for each new skill
* Contributors get credit via the issue and PR linkage

### Negative Consequences

* Slower than self-service PRs -- depends on maintainer availability
* Maintainers become a bottleneck if many requests come in
* Contributors don't learn the SKILL.md format (mitigated by contributing guide in docs)
* Requires maintainer familiarity with the source tool

## Links

* [GitHub Issue Forms syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
* [GitHub Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
* Related: [ADR-001](001-adopt-agent-skills-standard.html) (SKILL.md format), [ADR-003](003-documentation-embedding-strategy.html) (references/ structure), [ADR-004](004-installation-target-paths.html) (installation paths)
