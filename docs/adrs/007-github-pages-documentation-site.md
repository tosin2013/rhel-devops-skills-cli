---
title: "ADR-007: GitHub Pages Documentation Site"
nav_order: 7
parent: Architecture Decision Records
---

# ADR-007: GitHub Pages Documentation Site with Just the Docs

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team

## Context and Problem Statement

The rhel-devops-skills-cli project produces Architecture Decision Records, research documents, and a PRD that need to be accessible to the team and community. The PRD (Section 10) calls for a GitHub Pages documentation site but leaves the theme selection as an open question (OQ-14).

The ADRs contain external reference links to official documentation for Claude Code, Cursor IDE, Agent Skills, and MCP. A documentation site should make these navigable and searchable.

How should the project's documentation be published online?

## Decision Drivers

* ADRs and research docs are already in Markdown format in `docs/`
* The project is hosted on GitHub (`github.com/tosin2013/rhel-devops-skills-cli`)
* GitHub Pages provides free static site hosting with GitHub Actions deployment
* The MADR community site ([adr.github.io/madr](https://adr.github.io/madr/decisions/)) uses the Just the Docs theme
* The site must support search, navigation, Mermaid diagrams, and mobile responsiveness
* Minimal maintenance overhead is preferred -- content is already in `docs/`

## Considered Options

1. **Just the Docs** -- Jekyll theme with built-in search, navigation hierarchy, Mermaid support
2. **Minimal Mistakes** -- Feature-rich Jekyll theme with many layouts and plugins
3. **Cayman** -- Simple GitHub Pages default theme
4. **Plain GitHub Pages** -- No theme, raw Markdown rendering
5. **MkDocs with Material** -- Python-based static site generator (not Jekyll)

## Decision Outcome

Chosen option: **"Just the Docs"**, because it is purpose-built for documentation sites, provides built-in search and hierarchical navigation, supports Mermaid diagrams natively, is the same theme used by the MADR project, and requires minimal configuration beyond what already exists in `docs/`.

### Implementation

The site will be deployed at `https://tosin2013.github.io/rhel-devops-skills-cli/` using:

- **`docs/_config.yml`** -- Jekyll configuration with Just the Docs theme
- **`docs/Gemfile`** -- Ruby gem dependencies
- **`docs/index.md`** -- Landing page with navigation to ADRs and research
- **`.github/workflows/deploy-docs.yml`** -- GitHub Actions workflow for build and deploy

### Site Structure

```
docs/
  _config.yml           # Just the Docs theme config
  Gemfile               # Jekyll dependencies
  index.md              # Landing page
  adrs/                 # Architecture Decision Records (7 files)
    001-adopt-agent-skills-standard.md
    002-target-claude-code-and-cursor.md
    003-documentation-embedding-strategy.md
    004-installation-target-paths.md
    005-dual-mode-skills-and-rules.md
    006-shell-installer-architecture.md
    007-github-pages-documentation-site.md
  research/             # Research documents (5 files)
    agent-skills-open-standard.md
    claude-code-skill-system.md
    cursor-ide-skill-and-rules-system.md
    model-context-protocol-mcp.md
    rhel-bash-and-tooling-compatibility.md
```

### Positive Consequences

* ADRs and research are browsable and searchable online
* External reference links in ADRs are clickable
* Built-in search helps users find specific decisions and findings
* Mermaid diagram support renders architecture diagrams inline
* Mobile-responsive design for on-the-go access
* Same theme as the MADR community site -- familiar to ADR practitioners
* GitHub Actions automates deployment on every push to `main`
* No additional hosting costs (GitHub Pages is free for public repos)

### Negative Consequences

* Jekyll/Ruby toolchain required for local development preview
* Just the Docs theme updates may require Gemfile version bumps
* GitHub Pages build times add a few minutes to deployment
* Limited customization compared to a custom-built site

## Links

* [Just the Docs Theme](https://github.com/just-the-docs/just-the-docs) -- v0.12.0, January 2026
* [Just the Docs Template](https://github.com/just-the-docs/just-the-docs-template) -- Quick-start repository template
* [Just the Docs Configuration](https://just-the-docs.github.io/just-the-docs/docs/configuration/) -- Full configuration reference
* [MADR Decisions Site](https://adr.github.io/madr/decisions/) -- Example of Just the Docs for ADRs
* [ADR Community Templates](https://adr.github.io/adr-templates/) -- Standard ADR template formats
* [GitHub Pages Actions Deploy](https://github.com/actions/deploy-pages) -- Official GitHub Pages deployment action
* [GitHub Pages Static Site Deploy Guide](https://dev.to/profiterole/how-to-deploy-a-static-website-to-github-pages-in-2026-step-by-step-10oj)
* Related: PRD Section 10 "GitHub Pages Documentation Site" (OQ-14 theme selection)
