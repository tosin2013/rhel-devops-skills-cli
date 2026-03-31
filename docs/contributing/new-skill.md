---
title: Requesting a New Skill
parent: Contributing
nav_order: 1
---

# Requesting a New Skill

We use a curated contribution model: community members request new skills via GitHub Issues, and maintainers build them.

## Process

1. **Open an Issue** using the [New Skill Request template](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new?template=new-skill-request.yml)
2. **Fill in the details**: repository URL, documentation paths, when-to-use triggers
3. **A maintainer reviews** the request and clones the source repo to understand the tool
4. **The skill is built** based on actual repository content (no assumptions)
5. **A PR is opened** for review, and the skill is added to the installer

## What Makes a Good Skill Request

- **Clear source repository** — the Git URL and branch
- **Identified documentation** — which files in the repo should be fetched
- **Use-case description** — when should the AI assistant activate this skill?
- **Example interactions** — what questions would a user ask?

## Skill Structure

Each skill consists of:

```
skills/<name>/
  config.sh           # Repository URL, branch, doc paths
  SKILL.md            # Agent skill definition (YAML frontmatter + Markdown)
  references/
    REFERENCE.md      # Index of available documentation
  rules/
    <name>.mdc        # Optional Cursor-specific rules
```

## Validation Checklist

Before a skill is merged, maintainers verify:

- [ ] Source repository is accessible and public
- [ ] Documentation paths exist in the repo
- [ ] `SKILL.md` accurately describes the tool based on actual repo content
- [ ] "When to Use" triggers are specific and useful
- [ ] `config.sh` values are correct
- [ ] Tests pass on RHEL and macOS
