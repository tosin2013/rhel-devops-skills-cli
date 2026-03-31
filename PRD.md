# Product Requirements Document (PRD)
## RHEL DevOps Skills CLI - Claude & Cursor Skills Installer

**Document Version:** 1.0  
**Created:** 2024-03-31  
**Last Updated:** 2024-03-31  
**Status:** Draft - Pending Technical Research

---

## Table of Contents

1. [Introduction/Overview](#1-introductionoverview)
2. [Goals](#2-goals)
3. [User Stories / Features](#3-user-stories--features)
4. [Acceptance Criteria](#4-acceptance-criteria)
5. [Technical Requirements](#5-technical-requirements)
6. [Edge Cases & Error Handling](#6-edge-cases--error-handling)
7. [Open Questions / Future Considerations](#7-open-questions--future-considerations)
8. [Appendices](#8-appendices)
9. [Upgrade Strategy](#9-upgrade-strategy)
10. [GitHub Pages Documentation Site](#10-github-pages-documentation-site)
11. [Updated Repository Structure](#11-updated-repository-structure)
12. [Updated Command Reference](#12-updated-command-reference)
13. [Updated Open Questions](#13-updated-open-questions)
14. [Document Control](#14-document-control)

---

## 1. Introduction/Overview

### Project Name
**rhel-devops-skills-cli**

### Purpose
Create a centralized repository and installation system that enables users to easily install and configure AI assistant skills (for Claude Desktop and Cursor IDE) that provide deep knowledge and assistance for working with RHEL DevOps tooling, specifically:
- AgnosticD v2 (catalog item development and deployment automation)
- Field-Sourced Content Template (OpenShift GitOps-based workshop/demo deployment)
- Patternizer (Kubernetes/OpenShift pattern generation)

### Problem Statement
Developers and DevOps engineers working with AgnosticD v2, RHPDS field-sourced content, and Kubernetes/OpenShift patterns need AI assistance that understands these specific tools, their conventions, workflows, and best practices. Currently, AI assistants lack this specialized knowledge, requiring users to manually provide context and documentation repeatedly.

### Solution Overview
A shell script-based installation system that:
1. Provides individual skills for each tool (agnosticd, field-sourced-content, patternizer)
2. Includes static copies of official documentation for each skill
3. Installs skills to Claude Desktop and/or Cursor IDE
4. Tracks installed skills via a registry file
5. Supports installation, updates, upgrades, and uninstallation of skills
6. Provides comprehensive documentation via GitHub Pages

---

## 2. Goals

### Business Goals
- Reduce onboarding time for developers working with RHEL DevOps tools
- Standardize knowledge and best practices across teams
- Improve developer productivity by providing context-aware AI assistance
- Lower the barrier to entry for complex tools like AgnosticD v2
- Build a community around RHEL DevOps tooling

### Product Goals
- Create a simple, shell-based installation experience (`./install.sh --skill <name>`)
- Maintain up-to-date documentation within skills through periodic updates
- Support both Claude Desktop and Cursor IDE
- Enable users to selectively install only the skills they need
- Provide clear feedback and error handling during installation
- Enable easy upgrades for installer and skills
- Provide comprehensive online documentation via GitHub Pages

### Success Metrics
- Installation success rate > 95%
- Time to install all three skills < 5 minutes
- User ability to get relevant AI assistance for tool-specific tasks without manual context provision
- Positive user feedback on skill accuracy and usefulness
- GitHub Pages monthly visitors > 5000
- Community contributions (issues, PRs, discussions) > 20/month

---

## 3. User Stories / Features

### Epic 1: Skill Installation

**US-1.1: Install Single Skill**
- **As a** DevOps engineer
- **I want to** install a specific skill (agnosticd, field-sourced-content, or patternizer)
- **So that** Claude/Cursor can assist me with that specific tool

**US-1.2: Install Multiple Skills**
- **As a** developer working with multiple RHEL DevOps tools
- **I want to** install multiple skills in one command
- **So that** I can quickly set up my AI assistant for all my tools

**US-1.3: Install All Skills**
- **As a** new team member
- **I want to** install all available skills at once
- **So that** I have complete AI assistance for the entire RHEL DevOps toolchain

**US-1.4: Choose Target IDE**
- **As a** user of Claude Desktop or Cursor
- **I want to** specify which IDE(s) to install skills for
- **So that** skills are only installed where I need them

### Epic 2: Skill Management

**US-2.1: List Available Skills**
- **As a** user
- **I want to** see all available skills before installation
- **So that** I can decide which ones I need

**US-2.2: List Installed Skills**
- **As a** user
- **I want to** see which skills are currently installed
- **So that** I know what's configured on my system

**US-2.3: Update Skill**
- **As a** user
- **I want to** update a skill to get the latest documentation
- **So that** my AI assistant has current information

**US-2.4: Uninstall Skill**
- **As a** user
- **I want to** remove a skill I no longer need
- **So that** I can keep my system clean

**US-2.5: Verify Skill Installation**
- **As a** user
- **I want to** verify that a skill is correctly installed
- **So that** I can troubleshoot if something isn't working

### Epic 3: AgnosticD v2 Skill

**US-3.1: Setup Assistance**
- **As a** developer new to AgnosticD v2
- **I want** AI assistance with initial setup (Python venv, dependencies, pre-commit hooks)
- **So that** I can quickly get started following best practices

**US-3.2: Catalog Item Creation**
- **As a** catalog item developer
- **I want** AI assistance to generate new catalog item structures
- **So that** I follow the correct directory layout and file conventions

**US-3.3: Configuration Validation**
- **As a** catalog item developer
- **I want** AI assistance to validate my catalog item configuration
- **So that** I catch errors before deployment

**US-3.4: Documentation Generation**
- **As a** catalog item developer
- **I want** AI assistance to generate README and documentation
- **So that** my catalog items are properly documented

**US-3.5: Workflow Guidance**
- **As a** developer
- **I want** AI assistance with ansible-navigator commands and execution environments
- **So that** I can test and deploy catalog items correctly

### Epic 4: Field-Sourced Content Skill

**US-4.1: Repository Initialization**
- **As a** content developer
- **I want** AI assistance to initialize a new field-sourced content repository
- **So that** I start with the correct template structure

**US-4.2: Helm Chart Generation**
- **As a** content developer
- **I want** AI assistance to generate Helm charts following the template patterns
- **So that** my GitOps deployments follow best practices

**US-4.3: Component Creation**
- **As a** content developer
- **I want** AI assistance to add new components to my App of Apps
- **So that** I can extend my deployment with proper structure

**US-4.4: Ansible Runner Configuration**
- **As a** content developer using the Ansible approach
- **I want** AI assistance to configure Ansible Runner jobs
- **So that** my playbooks execute correctly in the GitOps environment

**US-4.5: LiteMaaS Integration**
- **As a** content developer creating AI/LLM demos
- **I want** AI assistance to configure LiteMaaS/MaaS integration
- **So that** my demos have proper API key injection

**US-4.6: GitOps Validation**
- **As a** content developer
- **I want** AI assistance to validate my GitOps repository structure
- **So that** deployments succeed on RHDP

### Epic 5: Patternizer Skill

**US-5.1: Pattern Generation**
- **As a** Kubernetes/OpenShift architect
- **I want** AI assistance to generate infrastructure patterns
- **So that** I can quickly scaffold common deployment patterns

**US-5.2: Pattern Application**
- **As a** developer
- **I want** AI assistance to apply existing patterns to my project
- **So that** I follow established architectural standards

**US-5.3: Pattern Validation**
- **As a** developer
- **I want** AI assistance to validate pattern definitions
- **So that** my patterns are correct before deployment

**US-5.4: Pattern Discovery**
- **As a** developer
- **I want** AI assistance to browse and search available patterns
- **So that** I can find the right pattern for my use case

### Epic 6: Upgrade Management

**US-6.1: Upgrade Installer**
- **As a** user with an older version of rhel-devops-skills-cli
- **I want to** upgrade the installer itself
- **So that** I have access to the latest features and bug fixes

**US-6.2: Upgrade All Skills**
- **As a** user
- **I want to** upgrade all installed skills at once
- **So that** I can quickly get the latest documentation and features

**US-6.3: Selective Upgrade**
- **As a** user
- **I want to** upgrade specific skills
- **So that** I can control which skills get updated

**US-6.4: Auto-Upgrade Check**
- **As a** user
- **I want to** be notified when upgrades are available
- **So that** I can keep my skills current

### Epic 7: Documentation and Community

**US-7.1: Browse Skills Online**
- **As a** potential user
- **I want to** browse available skills on a website
- **So that** I can learn about them before installing

**US-7.2: Installation Guide**
- **As a** new user
- **I want to** follow a step-by-step installation guide
- **So that** I can successfully install skills

**US-7.3: Skill Documentation**
- **As a** user
- **I want to** read skill documentation online
- **So that** I can learn how to use each skill

**US-7.4: Troubleshooting Guide**
- **As a** user experiencing issues
- **I want to** access troubleshooting documentation
- **So that** I can resolve problems myself

**US-7.5: Command Reference**
- **As a** user
- **I want to** access a complete command reference
- **So that** I can use all available features

**US-7.6: Community Contributions**
- **As a** community member
- **I want to** learn how to contribute new skills
- **So that** I can share my knowledge

**US-7.7: Release Notes**
- **As a** user
- **I want to** read release notes and changelogs
- **So that** I know what's new in each version

---

## 4. Acceptance Criteria

### AC-1: Installation System

**AC-1.1: Single Skill Installation**
- GIVEN the user has cloned rhel-devops-skills-cli
- WHEN they run `./install.sh --skill agnosticd`
- THEN the agnosticd skill is installed to the appropriate IDE location(s)
- AND the registry file is updated with installation details
- AND success message is displayed with verification instructions

**AC-1.2: Multiple Skill Installation**
- GIVEN the user wants multiple skills
- WHEN they run `./install.sh --skill agnosticd --skill field-sourced-content`
- THEN both skills are installed successfully
- AND the registry tracks both installations
- AND a summary of installed skills is displayed

**AC-1.3: All Skills Installation**
- GIVEN the user wants all available skills
- WHEN they run `./install.sh --all`
- THEN all three skills (agnosticd, field-sourced-content, patternizer) are installed
- AND the registry reflects all installations
- AND installation summary is displayed

**AC-1.4: IDE Selection**
- GIVEN the user has Claude Desktop installed
- WHEN they run `./install.sh --skill agnosticd --ide claude`
- THEN the skill is installed only to Claude Desktop's skill directory
- AND Cursor is not affected

**AC-1.5: Default IDE Behavior**
- GIVEN the user doesn't specify --ide flag
- WHEN they run `./install.sh --skill agnosticd`
- THEN the installer detects which IDE(s) are installed
- AND installs to all detected IDEs
- AND informs the user which IDEs were configured

**AC-1.6: Missing IDE Handling**
- GIVEN neither Claude Desktop nor Cursor is installed
- WHEN the user runs `./install.sh --skill agnosticd`
- THEN a clear error message is displayed
- AND installation instructions for Claude/Cursor are provided
- AND the script exits with non-zero status

### AC-2: Skill Management

**AC-2.1: List Available Skills**
- GIVEN the user wants to see available skills
- WHEN they run `./install.sh --list`
- THEN all available skills are displayed with descriptions
- AND repository URLs are shown
- AND current version information is included

**AC-2.2: List Installed Skills**
- GIVEN the user has installed some skills
- WHEN they run `./install.sh --list-installed`
- THEN all installed skills are displayed
- AND installation dates are shown
- AND target IDEs are listed
- AND documentation version/date is included

**AC-2.3: Update Skill**
- GIVEN a skill is already installed
- WHEN the user runs `./install.sh --update agnosticd`
- THEN the latest documentation is fetched from the source repository
- AND the skill configuration is updated
- AND the registry is updated with new fetch date and commit hash
- AND a summary of changes is displayed

**AC-2.4: Uninstall Skill**
- GIVEN a skill is installed
- WHEN the user runs `./install.sh --uninstall agnosticd`
- THEN the skill is removed from all IDE locations
- AND the registry is updated to remove the skill entry
- AND confirmation message is displayed

**AC-2.5: Verify Installation**
- GIVEN a skill is installed
- WHEN the user runs `./install.sh --verify agnosticd`
- THEN the script checks for skill files in expected locations
- AND validates skill configuration format
- AND checks documentation files exist
- AND reports status (OK, Missing, Corrupted)

### AC-3: Documentation Management

**AC-3.1: Documentation Fetching**
- GIVEN a skill is being installed
- WHEN the installer runs
- THEN it fetches the specified documentation files from the source repository
- AND stores them in the skill's docs/ directory
- AND records the commit hash and fetch date in the registry

**AC-3.2: Static Documentation Storage**
- GIVEN documentation has been fetched
- WHEN the skill is installed
- THEN documentation files are stored as static copies
- AND the skill configuration references these local files
- AND Claude/Cursor can access them without network requests

**AC-3.3: Documentation Update**
- GIVEN a skill's documentation is outdated
- WHEN the user runs `./install.sh --update agnosticd`
- THEN new documentation is fetched from the source repository
- AND old documentation is backed up before replacement
- AND the registry reflects the new documentation version

### AC-4: AgnosticD Skill Capabilities

**AC-4.1: Setup Documentation Access**
- GIVEN the agnosticd skill is installed
- WHEN a user asks Claude/Cursor about AgnosticD v2 setup
- THEN the AI references the local setup.adoc documentation
- AND provides accurate, step-by-step guidance
- AND includes relevant commands and examples

**AC-4.2: Catalog Item Structure Knowledge**
- GIVEN the agnosticd skill is installed
- WHEN a user asks to create a new catalog item
- THEN the AI explains the required directory structure
- AND lists required files (defaults/main.yml, tasks/main.yml, meta/main.yml, README.adoc)
- AND provides templates or examples

**AC-4.3: Best Practices Guidance**
- GIVEN the agnosticd skill is installed
- WHEN a user asks about AgnosticD best practices
- THEN the AI provides guidance based on official documentation
- AND references specific sections of setup.adoc
- AND includes examples from the documentation

### AC-5: Field-Sourced Content Skill Capabilities

**AC-5.1: Template Structure Knowledge**
- GIVEN the field-sourced-content skill is installed
- WHEN a user asks about the template structure
- THEN the AI explains the Helm vs Ansible approaches
- AND describes the App of Apps pattern
- AND references the examples/ directory structure

**AC-5.2: GitOps Configuration Guidance**
- GIVEN the field-sourced-content skill is installed
- WHEN a user asks about GitOps configuration
- THEN the AI explains the required Helm chart structure
- AND describes values.yaml requirements
- AND provides guidance on component enable/disable patterns

**AC-5.3: LiteMaaS Integration Knowledge**
- GIVEN the field-sourced-content skill is installed
- WHEN a user asks about LiteMaaS integration
- THEN the AI explains the API key provisioning process
- AND describes how credentials are injected into Helm values
- AND provides configuration examples

### AC-6: Patternizer Skill Capabilities

**AC-6.1: Pattern Generation Knowledge**
- GIVEN the patternizer skill is installed
- WHEN a user asks about generating Kubernetes/OpenShift patterns
- THEN the AI provides guidance based on patternizer documentation
- AND explains available pattern types
- AND provides usage examples

**AC-6.2: Pattern Application Guidance**
- GIVEN the patternizer skill is installed
- WHEN a user asks how to apply a pattern
- THEN the AI explains the application process
- AND references relevant patternizer commands
- AND provides examples from documentation

### AC-7: Error Handling

**AC-7.1: Network Failure**
- GIVEN the installer is fetching documentation
- WHEN a network error occurs
- THEN a clear error message is displayed
- AND the installation is rolled back
- AND the user is advised to check network connectivity and retry

**AC-7.2: Permission Denied**
- GIVEN the installer needs to write to skill directories
- WHEN permission is denied
- THEN a clear error message is displayed
- AND the required permissions are explained
- AND suggestions for resolution are provided

**AC-7.3: Corrupted Installation**
- GIVEN a skill installation is interrupted
- WHEN the user runs `./install.sh --verify agnosticd`
- THEN the corruption is detected
- AND the user is prompted to reinstall
- AND partial installation is cleaned up

**AC-7.4: Dependency Missing**
- GIVEN required tools (git, curl) are not installed
- WHEN the installer runs
- THEN missing dependencies are detected early
- AND a clear error message lists what's missing
- AND installation instructions for dependencies are provided

### AC-8: Registry Management

**AC-8.1: Registry Creation**
- GIVEN no skills have been installed yet
- WHEN the first skill is installed
- THEN a registry file is created in the user's home directory
- AND it contains the installation details for that skill

**AC-8.2: Registry Updates**
- GIVEN skills are installed, updated, or removed
- WHEN any skill management operation completes
- THEN the registry file is updated atomically
- AND the previous registry is backed up
- AND the registry remains valid YAML

**AC-8.3: Registry Corruption Recovery**
- GIVEN the registry file is corrupted
- WHEN any skill operation is attempted
- THEN the corruption is detected
- AND the user is warned
- AND a new registry is created from detected installations

### AC-9: Upgrade System

**AC-9.1: Installer Self-Upgrade**
- GIVEN a new version of the installer is available
- WHEN the user runs `./install.sh --upgrade-installer`
- THEN the installer downloads the new version
- AND backs up the current version
- AND replaces itself with the new version
- AND validates the upgrade
- AND displays what changed

**AC-9.2: Upgrade All Skills**
- GIVEN multiple skills have updates available
- WHEN the user runs `./install.sh --upgrade-all`
- THEN all skills are upgraded to latest versions
- AND documentation is refreshed
- AND registry is updated
- AND a summary of all upgrades is displayed

**AC-9.3: Update Check**
- GIVEN the user wants to check for updates
- WHEN they run `./install.sh --check-updates`
- THEN the installer checks GitHub for new versions
- AND displays available updates for installer and skills
- AND shows release notes for each update
- AND prompts to upgrade

**AC-9.4: Auto-Update Notification**
- GIVEN auto-update checking is enabled
- WHEN the user runs any install.sh command
- THEN the installer checks for updates in the background
- AND displays a notification if updates are available
- AND does not interrupt the current operation

### AC-10: GitHub Pages

**AC-10.1: Site Deployment**
- GIVEN changes are pushed to the main branch
- WHEN the GitHub Actions workflow runs
- THEN the documentation site is built successfully
- AND deployed to GitHub Pages
- AND accessible at the configured URL
- AND all links work correctly

**AC-10.2: Navigation**
- GIVEN a user visits the documentation site
- WHEN they navigate through the site
- THEN all navigation links work correctly
- AND the navigation menu is intuitive
- AND breadcrumbs show current location
- AND mobile navigation works on small screens

**AC-10.3: Search Functionality**
- GIVEN a user wants to find specific information
- WHEN they use the search feature
- THEN relevant results are displayed within 1 second
- AND results link to the correct pages
- AND search works across all documentation

**AC-10.4: Mobile Responsiveness**
- GIVEN a user accesses the site on mobile
- WHEN they view any page
- THEN the layout adapts to mobile screen
- AND all features remain accessible
- AND text is readable without zooming
- AND images scale appropriately

**AC-10.5: Code Examples**
- GIVEN a page contains code examples
- WHEN a user views the page
- THEN code is syntax highlighted correctly
- AND copy buttons work for all code blocks
- AND code blocks are scrollable if needed
- AND line numbers are displayed (if enabled)

**AC-10.6: Performance**
- GIVEN a user accesses any page
- WHEN the page loads
- THEN initial load time is < 3 seconds
- AND subsequent page loads are < 1 second
- AND images are optimized
- AND CSS/JS is minified

---

## 5. Technical Requirements

### 5.1 Architecture Overview

**System Components:**
1. **rhel-devops-skills-cli Repository**: Central repository containing skill definitions, installation scripts, and documentation
2. **Installation Scripts**: Shell scripts for installing, updating, and managing skills
3. **Skill Definitions**: Configuration files that define each skill for Claude/Cursor
4. **Documentation Storage**: Static copies of official documentation embedded in skills
5. **Registry System**: YAML file tracking installed skills and their metadata
6. **GitHub Pages Site**: Comprehensive online documentation and community hub

**Technology Stack:**
- Shell scripting (bash) for installation and management
- YAML for configuration and registry
- JSON/YAML for skill definitions (format TBD based on Claude/Cursor requirements)
- Git for repository management and documentation fetching
- Jekyll for GitHub Pages site generation
- GitHub Actions for CI/CD and documentation deployment

### 5.2 Repository Structure

```
rhel-devops-skills-cli/
├── README.md                          # Main repository documentation
├── LICENSE                            # License file
├── install.sh                         # Main installation script
├── skills/
│   ├── agnosticd/
│   │   ├── skill.json                 # Skill definition (format TBD)
│   │   ├── README.md                  # Skill-specific documentation
│   │   ├── docs/                      # Static documentation copies
│   │   │   ├── setup.adoc             # From agnosticd-v2 repo
│   │   │   ├── catalog-items.adoc     # Additional docs as needed
│   │   │   └── ...
│   │   └── install.sh                 # Skill-specific installer
│   ├── field-sourced-content/
│   │   ├── skill.json
│   │   ├── README.md
│   │   ├── docs/
│   │   │   ├── README.md              # From template repo
│   │   │   ├── examples.md            # Documentation of examples
│   │   │   └── ...
│   │   └── install.sh
│   └── patternizer/
│       ├── skill.json
│       ├── README.md
│       ├── docs/
│       │   ├── README.md              # From patternizer repo
│       │   └── ...
│       └── install.sh
├── lib/
│   ├── common.sh                      # Shared utility functions
│   ├── fetch-docs.sh                  # Documentation fetching utilities
│   ├── registry.sh                    # Registry management functions
│   ├── validate.sh                    # Validation utilities
│   └── upgrade.sh                     # Upgrade utilities
├── docs/                              # GitHub Pages content
│   ├── index.md
│   ├── _config.yml
│   ├── Gemfile
│   ├── getting-started/
│   │   ├── index.md
│   │   ├── installation.md
│   │   ├── quick-start.md
│   │   ├── prerequisites.md
│   │   └── first-skill.md
│   ├── skills/
│   │   ├── index.md
│   │   ├── agnosticd.md
│   │   ├── field-sourced-content.md
│   │   └── patternizer.md
│   ├── guides/
│   │   ├── index.md
│   │   ├── upgrade-guide.md
│   │   ├── troubleshooting.md
│   │   ├── best-practices.md
│   │   └── faq.md
│   ├── reference/
│   │   ├── index.md
│   │   ├── cli-reference.md
│   │   ├── configuration.md
│   │   ├── file-locations.md
│   │   ├── exit-codes.md
│   │   └── registry-format.md
│   ├── contributing/
│   │   ├── index.md
│   │   ├── creating-skills.md
│   │   ├── documentation.md
│   │   ├── testing.md
│   │   └── code-of-conduct.md
│   ├── examples/
│   │   ├── index.md
│   │   ├── agnosticd-workflow.md
│   │   ├── field-sourced-demo.md
│   │   └── patternizer-usage.md
│   ├── releases/
│   │   ├── index.md
│   │   ├── v1.2.3.md
│   │   └── changelog.md
│   ├── blog/
│   │   ├── index.md
│   │   └── _posts/
│   └── assets/
│       ├── css/
│       │   └── custom.css
│       ├── images/
│       │   ├── logo.png
│       │   ├── favicon.ico
│       │   └── screenshots/
│       └── js/
│           ├── custom.js
│           └── search.js
├── tests/
│   ├── test-install.sh                # Installation tests
│   ├── test-update.sh                 # Update tests
│   ├── test-uninstall.sh              # Uninstall tests
│   └── test-upgrade.sh                # Upgrade tests
└── .github/
    └── workflows/
        ├── deploy-docs.yml            # Deploy GitHub Pages
        ├── test.yml                   # Run tests
        └── release.yml                # Release automation
```

### 5.3 Data Models

#### Registry File Format
**Location**: `~/.rhel-devops-skills/registry.yaml`

```yaml
version: "1.0"
installer_version: "1.2.3"
last_updated: "2024-03-31T10:30:00Z"
last_upgrade_check: "2024-03-31T10:30:00Z"
auto_check_updates: true
installed_skills:
  - name: agnosticd
    version: "1.0.0"
    available_version: "1.1.0"
    upgrade_available: true
    source_repo: "https://github.com/tosin2013/agnosticd-v2"
    docs_commit_hash: "abc123def456"
    docs_fetched_date: "2024-03-31T10:30:00Z"
    installed_date: "2024-03-31T10:30:00Z"
    installed_to:
      - ide: claude
        path: "~/.config/claude/skills/agnosticd"
      - ide: cursor
        path: "~/.cursor/skills/agnosticd"
  - name: field-sourced-content
    version: "1.0.0"
    available_version: "1.0.0"
    upgrade_available: false
    source_repo: "https://github.com/rhpds/field-sourced-content-template"
    docs_commit_hash: "def789ghi012"
    docs_fetched_date: "2024-03-31T10:31:00Z"
    installed_date: "2024-03-31T10:31:00Z"
    installed_to:
      - ide: claude
        path: "~/.config/claude/skills/field-sourced-content"
  - name: patternizer
    version: "1.0.0"
    available_version: "1.0.0"
    upgrade_available: false
    source_repo: "https://github.com/tosin2013/patternizer"
    docs_commit_hash: "jkl345mno678"
    docs_fetched_date: "2024-03-31T10:32:00Z"
    installed_date: "2024-03-31T10:32:00Z"
    installed_to:
      - ide: cursor
        path: "~/.cursor/skills/patternizer"
```

#### Skill Definition Format
**Note**: The exact format depends on Claude/Cursor skill system requirements. This is a proposed structure pending research.

```json
{
  "name": "agnosticd",
  "version": "1.0.0",
  "description": "AI assistance for AgnosticD v2 catalog item development and deployment",
  "author": "RHEL DevOps Team",
  "repository": "https://github.com/tosin2013/agnosticd-v2",
  "documentation": {
    "local_path": "./docs",
    "files": [
      {
        "path": "docs/setup.adoc",
        "source": "https://github.com/agnosticd/agnosticd-v2/blob/main/docs/setup.adoc",
        "type": "asciidoc"
      }
    ]
  },
  "references": [
    "https://github.com/agnosticd/agnosticd-v2/blob/main/docs/setup.adoc",
    "https://code.claude.com/docs/en/skills",
    "https://cursor.com/help/customization/skills"
  ],
  "instructions": "When assisting users with AgnosticD v2, reference the setup.adoc and other documentation in the docs/ directory. Help with catalog item creation, configuration validation, ansible-navigator usage, and deployment workflows.",
  "capabilities": [
    "catalog_item_creation",
    "configuration_validation",
    "documentation_generation",
    "workflow_guidance"
  ],
  "tools": []
}
```

### 5.4 API Specifications

#### GitHub API Usage
The installer will use GitHub API to fetch documentation:

```bash
# Fetch file from GitHub
curl -H "Accept: application/vnd.github.v3.raw" \
     https://api.github.com/repos/agnosticd/agnosticd-v2/contents/docs/setup.adoc
```

**API Endpoints Used:**
- `GET /repos/{owner}/{repo}/contents/{path}` - Fetch file content
- `GET /repos/{owner}/{repo}/commits/{ref}` - Get commit information for version tracking
- `GET /repos/{owner}/{repo}/releases/latest` - Check for latest release

**Rate Limiting Considerations:**
- GitHub API has rate limits (60 requests/hour unauthenticated, 5000/hour authenticated)
- Installer should cache fetched documentation
- Consider adding optional GitHub token support for higher limits
- Environment variable: `GITHUB_TOKEN`

#### Claude/Cursor Skill APIs
**Information needed:**
- How skills are registered with Claude Desktop
- How skills are registered with Cursor
- Configuration file formats and locations
- Skill activation/deactivation mechanisms
- Tool definition formats (if applicable)

**Research Required:**
- Review https://code.claude.com/docs/en/skills
- Review https://cursor.com/help/customization/skills
- Determine if MCP (Model Context Protocol) is used
- Identify configuration file locations and formats

### 5.5 Logic Overview

#### Installation Flow

```
1. User runs: ./install.sh --skill agnosticd --ide claude

2. Validate prerequisites
   - Check bash version >= 4.0
   - Check git is installed
   - Check curl is installed
   - Check target IDE is installed

3. Check if skill already installed
   - Read registry file
   - If installed, prompt: "Already installed. Update? [y/n]"
   - If yes, proceed to update flow

4. Fetch documentation
   - Clone/fetch from source repository
   - Extract specified documentation files
   - Store in skills/agnosticd/docs/
   - Record commit hash and fetch date

5. Prepare skill installation
   - Create target directory structure
   - Copy skill.json to target location
   - Copy documentation to target location
   - Set appropriate permissions

6. Install to IDE(s)
   - For Claude: Copy to ~/.config/claude/skills/agnosticd/
   - For Cursor: Copy to ~/.cursor/skills/agnosticd/
   - Validate installation

7. Update registry
   - Create/update ~/.rhel-devops-skills/registry.yaml
   - Record installation details
   - Backup previous registry

8. Display success message
   - Show installation summary
   - Provide verification instructions
   - Show next steps
```

#### Update Flow

```
1. User runs: ./install.sh --update agnosticd

2. Validate skill is installed
   - Check registry
   - If not installed, error and exit

3. Backup current installation
   - Copy current skill directory to backup location
   - Record backup path

4. Fetch latest documentation
   - Fetch from source repository
   - Compare commit hashes
   - If no changes, inform user and exit

5. Update skill files
   - Replace documentation files
   - Update skill.json if needed
   - Preserve user customizations (if any)

6. Update registry
   - Update docs_commit_hash
   - Update docs_fetched_date
   - Update last_updated timestamp

7. Validate updated installation
   - Run verification checks
   - If validation fails, restore from backup

8. Display update summary
   - Show what changed
   - Show new commit hash
   - Confirm success
```

#### Upgrade Flow

```
1. User runs: ./install.sh --upgrade-installer or --upgrade-all

2. Check for updates
   - Query GitHub releases API
   - Compare local version with remote version
   - Check registry versions with available versions

3. Download updates
   - Fetch new installer version (if applicable)
   - Fetch new skill definitions
   - Fetch updated documentation

4. Backup current installation
   - Backup installer scripts
   - Backup skill configurations
   - Backup registry

5. Apply updates
   - Update installer scripts
   - Update skill definitions
   - Update documentation
   - Migrate registry if needed

6. Validate upgrade
   - Run post-upgrade checks
   - Verify all skills still work
   - Rollback if validation fails

7. Clean up
   - Remove old backups (keep last 3)
   - Update registry with new versions
   - Display upgrade summary
```

#### Uninstall Flow

```
1. User runs: ./install.sh --uninstall agnosticd

2. Validate skill is installed
   - Check registry
   - If not installed, warn and exit

3. Prompt for confirmation
   - Show what will be removed
   - Confirm: "Remove agnosticd skill? [y/n]"

4. Remove skill files
   - Delete from Claude skills directory
   - Delete from Cursor skills directory
   - Keep backup for 7 days (optional)

5. Update registry
   - Remove skill entry
   - Update last_updated timestamp
   - Backup registry

6. Display confirmation
   - Show what was removed
   - Show backup location (if kept)
   - Confirm success
```

### 5.6 Integration Points

#### Source Repositories
- **agnosticd-v2**: https://github.com/tosin2013/agnosticd-v2
  - Documentation: docs/setup.adoc, docs/*.adoc
  - Default branch: main
  
- **field-sourced-content-template**: https://github.com/rhpds/field-sourced-content-template
  - Documentation: README.md, examples/
  - Default branch: main

- **patternizer**: https://github.com/tosin2013/patternizer
  - Documentation: README.md
  - Default branch: main

#### IDE Integration
- **Claude Desktop**
  - Configuration location: TBD (requires research)
  - Skill format: TBD (requires research)
  - Activation mechanism: TBD (requires research)
  - Documentation references: https://code.claude.com/docs/en/skills

- **Cursor**
  - Configuration location: TBD (requires research)
  - Skill format: TBD (requires research)
  - Activation mechanism: TBD (requires research)
  - Documentation references: https://cursor.com/help/customization/skills

#### File System
- Skills installed to: `~/.config/claude/skills/` and `~/.cursor/skills/` (tentative)
- Registry location: `~/.rhel-devops-skills/registry.yaml`
- Backup location: `~/.rhel-devops-skills/backups/`
- Log location: `~/.rhel-devops-skills/logs/`

#### GitHub Pages
- Site URL: `https://your-org.github.io/rhel-devops-skills-cli`
- Deployment: GitHub Actions workflow
- Build: Jekyll static site generator
- Theme: TBD (Cayman, Just the Docs, or Minimal Mistakes)

### 5.7 Security Considerations

**Documentation Fetching:**
- Verify SSL certificates when fetching from GitHub
- Validate file content before storage
- Check file sizes to prevent DoS via large files
- Sanitize file paths to prevent directory traversal

**File Permissions:**
- Skill files should be readable by user only (600)
- Directories should be user-accessible only (700)
- Registry file should be user-writable only (600)

**Script Execution:**
- Validate all user inputs
- Sanitize file paths to prevent directory traversal
- Use absolute paths where possible
- Avoid eval and similar dangerous constructs
- Use shellcheck for static analysis

**Credential Management:**
- Never store GitHub tokens in plain text
- Support environment variable for GitHub token (GITHUB_TOKEN)
- Warn users if using unauthenticated GitHub API
- Document rate limiting implications

**Upgrade Security:**
- Verify checksums/signatures of downloaded updates
- Use HTTPS for all downloads
- Validate version numbers to prevent downgrade attacks
- Backup before applying updates

---

## 6. Edge Cases & Error Handling

### 6.1 Installation Errors

**EC-1: Network Unavailable**
- **Scenario**: User has no internet connection during installation
- **Handling**: 
  - Detect network failure early
  - Display clear error message
  - Suggest offline installation method (if pre-fetched docs available)
  - Exit cleanly without partial installation

**EC-2: GitHub Rate Limit Exceeded**
- **Scenario**: Too many API requests to GitHub
- **Handling**:
  - Detect rate limit error
  - Display remaining rate limit and reset time
  - Suggest using GitHub token for higher limits
  - Offer to retry after rate limit reset

**EC-3: Target IDE Not Installed**
- **Scenario**: User specifies --ide claude but Claude Desktop is not installed
- **Handling**:
  - Detect missing IDE early in process
  - Display installation instructions for the IDE
  - Offer to install for other detected IDEs
  - Exit with helpful error message

**EC-4: Insufficient Disk Space**
- **Scenario**: Not enough disk space for documentation
- **Handling**:
  - Check available disk space before fetching
  - Calculate required space
  - Display clear error with space requirements
  - Clean up any partial downloads

**EC-5: Permission Denied**
- **Scenario**: Cannot write to skill directory
- **Handling**:
  - Detect permission issue
  - Explain required permissions
  - Suggest using sudo if appropriate
  - Offer alternative installation location

**EC-6: Corrupted Download**
- **Scenario**: Documentation file is corrupted during download
- **Handling**:
  - Validate file integrity (checksum if available)
  - Retry download up to 3 times
  - If still failing, report error and clean up
  - Log details for troubleshooting

### 6.2 Update Errors

**EC-7: Skill Modified by User**
- **Scenario**: User has customized skill files, update would overwrite
- **Handling**:
  - Detect modifications (compare checksums)
  - Warn user about customizations
  - Offer to backup customizations
  - Prompt for confirmation before overwriting

**EC-8: Downgrade Attempt**
- **Scenario**: Installed version is newer than available version
- **Handling**:
  - Detect version mismatch
  - Warn user about downgrade
  - Require explicit --force flag to proceed
  - Backup current version before downgrade

**EC-9: Partial Update Failure**
- **Scenario**: Update fails midway through process
- **Handling**:
  - Maintain backup of previous version
  - Detect failure and rollback automatically
  - Restore from backup
  - Report what failed and why

### 6.3 Uninstall Errors

**EC-10: Skill Not Found**
- **Scenario**: User tries to uninstall non-existent skill
- **Handling**:
  - Check registry first
  - Display helpful message
  - List installed skills
  - Exit gracefully

**EC-11: Partial Installation**
- **Scenario**: Skill partially installed (in one IDE but not registry)
- **Handling**:
  - Detect inconsistency
  - Offer to clean up orphaned files
  - Update registry to reflect actual state
  - Report what was found and cleaned

### 6.4 Registry Errors

**EC-12: Registry File Corrupted**
- **Scenario**: registry.yaml is malformed or corrupted
- **Handling**:
  - Detect YAML parsing errors
  - Attempt to restore from backup
  - If no backup, scan filesystem for installed skills
  - Rebuild registry from detected installations
  - Warn user about data loss

**EC-13: Registry Lock Conflict**
- **Scenario**: Multiple install processes running simultaneously
- **Handling**:
  - Implement file locking mechanism
  - Detect lock and wait (with timeout)
  - If timeout, prompt user to check for other processes
  - Exit safely if lock cannot be acquired

**EC-14: Registry Version Mismatch**
- **Scenario**: Registry format has changed between versions
- **Handling**:
  - Detect version mismatch
  - Attempt automatic migration
  - Backup old registry before migration
  - Report migration status
  - If migration fails, provide manual steps

### 6.5 Documentation Errors

**EC-15: Documentation File Missing**
- **Scenario**: Expected documentation file not found in source repo
- **Handling**:
  - Detect missing file
  - Log warning but continue installation
  - Update skill definition to reflect missing docs
  - Report missing files to user

**EC-16: Documentation Format Changed**
- **Scenario**: Documentation format has changed (e.g., moved from .adoc to .md)
- **Handling**:
  - Detect format change
  - Attempt to fetch new format
  - Update skill configuration
  - Report format change to user

**EC-17: Large Documentation Size**
- **Scenario**: Documentation files are unexpectedly large (>100MB)
- **Handling**:
  - Warn user about large download
  - Prompt for confirmation
  - Show progress during download
  - Offer to skip large files

### 6.6 Compatibility Errors

**EC-18: Unsupported OS**
- **Scenario**: Running on unsupported operating system
- **Handling**:
  - Detect OS early
  - Display supported OS list
  - Offer workarounds if available
  - Exit with clear error

**EC-19: Bash Version Too Old**
- **Scenario**: Bash version < 4.0
- **Handling**:
  - Check bash version at start
  - Display required version
  - Provide upgrade instructions
  - Exit gracefully

**EC-20: IDE Version Incompatible**
- **Scenario**: Claude/Cursor version doesn't support skills
- **Handling**:
  - Detect IDE version (if possible)
  - Check compatibility
  - Warn about potential issues
  - Offer to proceed anyway with --force

### 6.7 Validation Errors

**EC-21: Invalid Skill Name**
- **Scenario**: User specifies non-existent skill
- **Handling**:
  - Validate skill name against available skills
  - Display list of valid skill names
  - Suggest closest match (fuzzy matching)
  - Exit with helpful error

**EC-22: Invalid Command Combination**
- **Scenario**: User specifies conflicting flags (e.g., --install and --uninstall)
- **Handling**:
  - Validate command line arguments
  - Display usage information
  - Explain the conflict
  - Exit with error

**EC-23: Circular Dependency**
- **Scenario**: Skill dependencies create a circular reference (future consideration)
- **Handling**:
  - Detect circular dependency
  - Report the dependency chain
  - Refuse to install
  - Suggest resolution

### 6.8 Upgrade Errors

**EC-24: Upgrade Interrupted**
- **Scenario**: Upgrade process is interrupted (Ctrl+C, system crash)
- **Handling**:
  - Detect incomplete upgrade on next run
  - Offer to resume or rollback
  - Restore from backup if rollback chosen
  - Clean up partial upgrade files

**EC-25: Incompatible Upgrade**
- **Scenario**: New version requires breaking changes
- **Handling**:
  - Detect breaking changes
  - Display migration guide
  - Require explicit confirmation
  - Backup before proceeding

**EC-26: Rollback Failure**
- **Scenario**: Rollback after failed upgrade also fails
- **Handling**:
  - Log detailed error information
  - Preserve all backup files
  - Provide manual recovery instructions
  - Exit with error code

---

## 7. Open Questions / Future Considerations

### 7.1 Technical Research Needed

**OQ-1: Claude Desktop Skill Format**
- What is the exact format for Claude Desktop skills?
- Where are skills stored on the filesystem?
- How are skills registered/activated?
- What is the MCP (Model Context Protocol) structure?
- Are there tool definitions that can be included?

**OQ-2: Cursor Skill Format**
- What is the exact format for Cursor skills?
- Where are skills stored on the filesystem?
- How are skills registered/activated?
- Is the format identical to Claude or different?
- What capabilities do Cursor skills support?

**OQ-3: Skill Capabilities**
- Can skills define executable tools/commands?
- Can skills include code snippets or templates?
- Can skills access local files beyond documentation?
- What are the security boundaries for skills?

**OQ-4: Documentation Format**
- Do Claude/Cursor skills support AsciiDoc natively?
- Should documentation be converted to Markdown?
- Can documentation include images/diagrams?
- What is the maximum documentation size?

### 7.2 Scope and Features

**OQ-5: Repository Cloning**
- Should the installer optionally clone the source repositories?
- If yes, where should they be cloned?
- Should the skill reference the cloned repo?
- How to handle repository updates?

**OQ-6: Skill Dependencies**
- Should skills be able to depend on other skills?
- Should the installer handle dependency resolution?
- How to handle version conflicts?

**OQ-7: Skill Customization**
- Should users be able to customize skill behavior?
- Should there be a configuration file for each skill?
- How to preserve customizations during updates?

**OQ-8: Documentation Selection**
- Which specific documentation files should be included for each skill?
- Should users be able to select which docs to include?
- Should there be "minimal" vs "complete" installation options?

**OQ-9: Offline Installation**
- Should there be an offline installation mode?
- Should the repository include pre-fetched documentation?
- How to package for offline distribution?

**OQ-10: Multi-User Support**
- Should skills be installable system-wide?
- Should there be a shared skill cache?
- How to handle permissions in multi-user environments?

### 7.3 Upgrade Strategy

**OQ-11: Upgrade Frequency**
- How often should automatic update checks occur?
- Should there be configurable update channels (stable, beta)?
- Should upgrades require user confirmation by default?

**OQ-12: Breaking Changes**
- How to handle breaking changes in upgrades?
- Should there be migration scripts?
- How to communicate breaking changes to users?

**OQ-13: Rollback Strategy**
- How many previous versions to keep for rollback?
- Should rollback be automatic on failure?
- How to handle registry format changes during rollback?

### 7.4 GitHub Pages

**OQ-14: Theme Selection**
- Which Jekyll theme to use (Cayman, Just the Docs, Minimal Mistakes)?
- Should there be dark mode support?
- What level of customization is needed?

**OQ-15: Documentation Maintenance**
- Who is responsible for keeping docs updated?
- Should docs be auto-generated from code?
- How to handle versioned documentation?

**OQ-16: Community Features**
- Should there be a discussion forum on the site?
- Should there be user-submitted examples?
- How to moderate community contributions?

**OQ-17: Analytics**
- Should Google Analytics be enabled?
- What metrics should be tracked?
- Privacy considerations?

### 7.5 Future Enhancements

**FC-1: Web UI**
- Create a web-based skill browser and installer
- Visual skill management dashboard
- Online documentation viewer

**FC-2: Skill Marketplace**
- Central registry of community-contributed skills
- Skill ratings and reviews
- Automated skill discovery

**FC-3: Skill Development Tools**
- Template generator for creating new skills
- Validation tools for skill definitions
- Testing framework for skills

**FC-4: Team/Organization Features**
- Organization-wide skill distribution
- Centralized skill management
- Usage analytics and reporting

**FC-5: CI/CD Integration**
- Automated skill testing in CI pipelines
- Skill deployment automation
- Version management and release automation

**FC-6: Enhanced Documentation**
- Interactive tutorials within skills
- Video content support
- Code examples with syntax highlighting

**FC-7: Skill Versioning**
- Support for multiple versions of same skill
- Version pinning and constraints
- Automatic compatibility checking

**FC-8: Plugin Architecture**
- Allow third-party skill sources
- Custom documentation fetchers
- Extensible validation system

**FC-9: IDE Integration**
- Native IDE extensions for skill management
- In-IDE skill browser
- Skill usage analytics

**FC-10: Advanced Features**
- Skill composition (combine multiple skills)
- Context-aware skill activation
- Machine learning for skill recommendations

### 7.6 Documentation Requirements

**OQ-18: AgnosticD Documentation**
- Complete list of documentation files to include
- Specific sections most relevant to users
- Examples and templates to embed

**OQ-19: Field-Sourced Content Documentation**
- Which examples to include
- How to document both Helm and Ansible approaches
- LiteMaaS integration documentation details

**OQ-20: Patternizer Documentation**
- Complete understanding of patternizer functionality
- Common use cases and workflows
- Pattern catalog to include

### 7.7 Testing and Validation

**OQ-21: Testing Strategy**
- How to test skill functionality with Claude/Cursor?
- Automated testing approach
- User acceptance testing criteria

**OQ-22: Validation Metrics**
- How to measure skill effectiveness?
- What constitutes a successful installation?
- How to gather user feedback?

### 7.8 Maintenance and Support

**OQ-23: Update Frequency**
- How often should documentation be updated?
- Automated vs manual update triggers
- Notification system for available updates

**OQ-24: Support Model**
- How to handle user issues and questions?
- Documentation for troubleshooting
- Community support vs official support

**OQ-25: Versioning Strategy**
- Semantic versioning for skills?
- Compatibility matrix between skill and source repo versions
- Deprecation policy

### 7.9 Platform Support

**OQ-26: Operating System Support**
- macOS support (primary?)
- Linux support (which distributions?)
- Windows/WSL support
- Platform-specific installation paths

**OQ-27: Shell Compatibility**
- Bash version requirements
- Zsh compatibility
- Fish shell support

---

## 8. Appendices

### Appendix A: Command Reference

```bash
# Installation
./install.sh --skill <skill-name>                    # Install single skill
./install.sh --skill <skill1> --skill <skill2>       # Install multiple skills
./install.sh --all                                   # Install all skills
./install.sh --skill <skill-name> --ide claude       # Install for specific IDE
./install.sh --skill <skill-name> --ide cursor       # Install for Cursor
./install.sh --skill <skill-name> --ide both         # Install for both (default)

# Management
./install.sh --list                                  # List available skills
./install.sh --list-installed                        # List installed skills
./install.sh --update <skill-name>                   # Update skill documentation
./install.sh --uninstall <skill-name>                # Uninstall skill
./install.sh --verify <skill-name>                   # Verify installation

# Upgrades
./install.sh --check-updates                         # Check for available updates
./install.sh --upgrade-installer                     # Upgrade the installer itself
./install.sh --upgrade <skill-name>                  # Upgrade specific skill
./install.sh --upgrade-all                           # Upgrade all skills

# Utilities
./install.sh --help                                  # Show help
./install.sh --version                               # Show version
./install.sh --verbose                               # Verbose output
./install.sh --dry-run                               # Show what would be done
./install.sh --force                                 # Force operation
./install.sh --check-prereqs                         # Check prerequisites
```

### Appendix B: File Locations

```
# Installation Repository
~/workspace/rhel-devops-skills-cli/

# User Data
~/.rhel-devops-skills/
  ├── registry.yaml                    # Installed skills registry
  ├── backups/                         # Backup files
  │   ├── registry-2024-03-31.yaml
  │   └── agnosticd-2024-03-31/
  └── logs/                            # Installation logs
      └── install-2024-03-31.log

# Claude Desktop Skills (tentative)
~/.config/claude/skills/
  ├── agnosticd/
  │   ├── skill.json
  │   └── docs/
  ├── field-sourced-content/
  │   ├── skill.json
  │   └── docs/
  └── patternizer/
      ├── skill.json
      └── docs/

# Cursor Skills (tentative)
~/.cursor/skills/
  ├── agnosticd/
  ├── field-sourced-content/
  └── patternizer/
```

### Appendix C: Environment Variables

```bash
# Optional environment variables
GITHUB_TOKEN                # GitHub personal access token for higher API limits
RHEL_DEVOPS_SKILLS_HOME     # Override default installation directory
RHEL_DEVOPS_SKILLS_VERBOSE  # Enable verbose logging (true/false)
RHEL_DEVOPS_SKILLS_IDE      # Default IDE (claude, cursor, both)
```

### Appendix D: Exit Codes

```
0   - Success
1   - General error
2   - Invalid arguments
3   - Missing dependencies
4   - Network error
5   - Permission denied
6   - Skill not found
7   - Installation failed
8   - Update failed
9   - Uninstallation failed
10  - Validation failed
11  - Registry error
12  - Upgrade failed
```

### Appendix E: Source Repository References

**AgnosticD v2:**
- Main repo: https://github.com/agnosticd/agnosticd-v2
- Default fork: https://github.com/tosin2013/agnosticd-v2
- Key documentation: docs/setup.adoc
- Branch: main

**Field-Sourced Content Template:**
- Repo: https://github.com/rhpds/field-sourced-content-template
- Key documentation: README.md, examples/
- Branch: main

**Patternizer:**
- Repo: https://github.com/tosin2013/patternizer
- Key documentation: README.md
- Branch: main

**Claude Skills Documentation:**
- https://code.claude.com/docs/en/skills

**Cursor Skills Documentation:**
- https://cursor.com/help/customization/skills

### Appendix F: GitHub Pages Site Map

```
https://your-org.github.io/rhel-devops-skills-cli/
├── /                                   # Homepage
├── /getting-started/
│   ├── /installation                   # Installation guide
│   ├── /quick-start                    # Quick start tutorial
│   ├── /prerequisites                  # System requirements
│   └── /first-skill                    # Installing first skill
├── /skills/
│   ├── /agnosticd                      # AgnosticD skill docs
│   ├── /field-sourced-content          # Field-sourced content docs
│   └── /patternizer                    # Patternizer skill docs
├── /guides/
│   ├── /upgrade-guide                  # Upgrading skills
│   ├── /troubleshooting                # Common issues
│   ├── /best-practices                 # Best practices
│   └── /faq                            # FAQ
├── /reference/
│   ├── /cli-reference                  # Complete CLI reference
│   ├── /configuration                  # Configuration options
│   ├── /file-locations                 # File system layout
│   ├── /exit-codes                     # Exit code reference
│   └── /registry-format                # Registry file format
├── /contributing/
│   ├── /creating-skills                # How to create skills
│   ├── /documentation                  # Documentation standards
│   ├── /testing                        # Testing guidelines
│   └── /code-of-conduct                # Code of conduct
├── /examples/
│   ├── /agnosticd-workflow             # AgnosticD examples
│   ├── /field-sourced-demo             # Field-sourced examples
│   └── /patternizer-usage              # Patternizer examples
├── /releases/
│   ├── /v1.2.3                         # Release notes
│   └── /changelog                      # Complete changelog
└── /blog/                              # Blog posts
```

---

## 9. Upgrade Strategy

### 9.1 Upgrade Paths

**US-9.1: Upgrade Installer**
- **As a** user with an older version of rhel-devops-skills-cli
- **I want to** upgrade the installer itself
- **So that** I have access to the latest features and bug fixes

**US-9.2: Upgrade All Skills**
- **As a** user
- **I want to** upgrade all installed skills at once
- **So that** I can quickly get the latest documentation and features

**US-9.3: Selective Upgrade**
- **As a** user
- **I want to** upgrade specific skills
- **So that** I can control which skills get updated

**US-9.4: Auto-Upgrade Check**
- **As a** user
- **I want to** be notified when upgrades are available
- **So that** I can keep my skills current

### 9.2 Upgrade Technical Specifications

#### Self-Upgrade Mechanism

```bash
# Upgrade the installer itself
./install.sh --upgrade-installer

# Check for updates
./install.sh --check-updates

# Upgrade all skills
./install.sh --upgrade-all

# Upgrade specific skill
./install.sh --upgrade agnosticd

# Auto-check on every run (configurable)
./install.sh --skill agnosticd  # Checks for updates first
```

#### Upgrade Process Flow

```
1. Check for updates
   - Compare local version with remote version
   - Check GitHub releases API
   - Compare registry versions with available versions

2. Download updates
   - Fetch new installer version (if applicable)
   - Fetch new skill definitions
   - Fetch updated documentation

3. Backup current installation
   - Backup installer scripts
   - Backup skill configurations
   - Backup registry

4. Apply updates
   - Update installer scripts
   - Update skill definitions
   - Update documentation
   - Migrate registry if needed

5. Validate upgrade
   - Run post-upgrade checks
   - Verify all skills still work
   - Rollback if validation fails

6. Clean up
   - Remove old backups (keep last 3)
   - Update registry with new versions
   - Display upgrade summary
```

#### Version Management

```yaml
# Registry includes version tracking
version: "1.0"
installer_version: "1.2.3"
last_upgrade_check: "2024-03-31T10:30:00Z"
auto_check_updates: true
installed_skills:
  - name: agnosticd
    version: "1.0.0"
    available_version: "1.1.0"  # Populated during update check
    upgrade_available: true
```

### 9.3 Upgrade Acceptance Criteria

**AC-9.1: Installer Self-Upgrade**
- GIVEN a new version of the installer is available
- WHEN the user runs `./install.sh --upgrade-installer`
- THEN the installer downloads the new version
- AND backs up the current version
- AND replaces itself with the new version
- AND validates the upgrade
- AND displays what changed

**AC-9.2: Upgrade All Skills**
- GIVEN multiple skills have updates available
- WHEN the user runs `./install.sh --upgrade-all`
- THEN all skills are upgraded to latest versions
- AND documentation is refreshed
- AND registry is updated
- AND a summary of all upgrades is displayed

**AC-9.3: Update Check**
- GIVEN the user wants to check for updates
- WHEN they run `./install.sh --check-updates`
- THEN the installer checks GitHub for new versions
- AND displays available updates for installer and skills
- AND shows release notes for each update
- AND prompts to upgrade

**AC-9.4: Auto-Update Notification**
- GIVEN auto-update checking is enabled
- WHEN the user runs any install.sh command
- THEN the installer checks for updates in the background
- AND displays a notification if updates are available
- AND does not interrupt the current operation

---

## 10. GitHub Pages Documentation Site

### 10.1 Site Structure Overview

The GitHub Pages site serves as the primary documentation and community hub for RHEL DevOps Skills CLI. It provides:

- Comprehensive installation and usage guides
- Detailed skill documentation
- Troubleshooting resources
- API and CLI references
- Community contribution guidelines
- Release notes and changelog
- Blog for updates and announcements

### 10.2 Key Pages

#### Homepage (docs/index.md)
- Project overview and value proposition
- Quick start guide
- Featured skills with descriptions
- Latest updates and blog posts
- Community links

#### Getting Started Section
- **Installation Guide**: Step-by-step installation instructions
- **Prerequisites**: System requirements and dependencies
- **Quick Start**: Fast-track tutorial for first-time users
- **First Skill**: Guided walkthrough of installing first skill

#### Skills Section
- **AgnosticD**: Complete documentation for AgnosticD skill
- **Field-Sourced Content**: GitOps and RHPDS content documentation
- **Patternizer**: Kubernetes/OpenShift pattern generation guide

#### Guides Section
- **Upgrade Guide**: How to upgrade installer and skills
- **Troubleshooting**: Common issues and solutions
- **Best Practices**: Recommended workflows and patterns
- **FAQ**: Frequently asked questions

#### Reference Section
- **CLI Reference**: Complete command-line interface documentation
- **Configuration**: Configuration options and environment variables
- **File Locations**: File system layout and paths
- **Exit Codes**: Exit code meanings and troubleshooting
- **Registry Format**: Registry file structure and fields

#### Contributing Section
- **Creating Skills**: Guide for developing new skills
- **Documentation**: Documentation standards and style guide
- **Testing**: Testing guidelines and frameworks
- **Code of Conduct**: Community guidelines

#### Examples Section
- **AgnosticD Workflow**: Real-world AgnosticD usage examples
- **Field-Sourced Demo**: GitOps deployment examples
- **Patternizer Usage**: Pattern generation and application examples

#### Releases Section
- **Version-specific release notes**: Detailed changes for each version
- **Changelog**: Complete project history

#### Blog Section
- **Announcements**: New features and updates
- **Tutorials**: In-depth guides and walkthroughs
- **Community Spotlights**: User contributions and success stories

### 10.3 Technical Implementation

#### Jekyll Configuration

```yaml
# _config.yml
title: RHEL DevOps Skills
description: AI-powered assistance for RHEL DevOps tools
baseurl: "/rhel-devops-skills-cli"
url: "https://your-org.github.io"

theme: jekyll-theme-cayman
# Or: remote_theme: just-the-docs/just-the-docs

markdown: kramdown
highlighter: rouge

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-github-metadata
```

#### GitHub Actions Deployment

```yaml
# .github/workflows/deploy-docs.yml
name: Deploy GitHub Pages

on:
  push:
    branches: [main]
    paths: ['docs/**']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: docs
      - uses: actions/configure-pages@v4
      - run: bundle exec jekyll build
        working-directory: docs
      - uses: actions/upload-pages-artifact@v3
        with:
          path: docs/_site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
```

### 10.4 Design and User Experience

#### Navigation
- Clear, hierarchical navigation menu
- Breadcrumbs for context
- Search functionality
- Mobile-responsive design

#### Content Features
- Syntax-highlighted code blocks
- Copy-to-clipboard buttons
- Interactive examples
- Embedded diagrams and screenshots
- Version selector for documentation

#### Accessibility
- WCAG 2.1 AA compliance
- Semantic HTML
- Keyboard navigation
- Screen reader support
- High contrast mode

### 10.5 Maintenance and Updates

#### Content Updates
- Documentation updated with each release
- Blog posts for major announcements
- Community contributions via pull requests
- Automated link checking

#### Performance
- Optimized images
- Minified CSS/JS
- CDN for static assets
- Fast page load times (< 3 seconds)

#### Analytics
- Google Analytics (optional)
- Page view tracking
- Search query analysis
- User journey mapping

---

## 11. Updated Repository Structure

```
rhel-devops-skills-cli/
├── README.md
├── LICENSE
├── install.sh
├── skills/
│   ├── agnosticd/
│   │   ├── skill.json
│   │   ├── README.md
│   │   ├── docs/
│   │   └── install.sh
│   ├── field-sourced-content/
│   │   ├── skill.json
│   │   ├── README.md
│   │   ├── docs/
│   │   └── install.sh
│   └── patternizer/
│       ├── skill.json
│       ├── README.md
│       ├── docs/
│       └── install.sh
├── lib/
│   ├── common.sh
│   ├── fetch-docs.sh
│   ├── registry.sh
│   ├── validate.sh
│   └── upgrade.sh
├── docs/                              # GitHub Pages content
│   ├── index.md
│   ├── _config.yml
│   ├── Gemfile
│   ├── getting-started/
│   │   ├── index.md
│   │   ├── installation.md
│   │   ├── quick-start.md
│   │   ├── prerequisites.md
│   │   └── first-skill.md
│   ├── skills/
│   │   ├── index.md
│   │   ├── agnosticd.md
│   │   ├── field-sourced-content.md
│   │   └── patternizer.md
│   ├── guides/
│   │   ├── index.md
│   │   ├── upgrade-guide.md
│   │   ├── troubleshooting.md
│   │   ├── best-practices.md
│   │   └── faq.md
│   ├── reference/
│   │   ├── index.md
│   │   ├── cli-reference.md
│   │   ├── configuration.md
│   │   ├── file-locations.md
│   │   ├── exit-codes.md
│   │   └── registry-format.md
│   ├── contributing/
│   │   ├── index.md
│   │   ├── creating-skills.md
│   │   ├── documentation.md
│   │   ├── testing.md
│   │   └── code-of-conduct.md
│   ├── examples/
│   │   ├── index.md
│   │   ├── agnosticd-workflow.md
│   │   ├── field-sourced-demo.md
│   │   └── patternizer-usage.md
│   ├── releases/
│   │   ├── index.md
│   │   ├── v1.2.3.md
│   │   └── changelog.md
│   ├── blog/
│   │   ├── index.md
│   │   └── _posts/
│   └── assets/
│       ├── css/
│       │   └── custom.css
│       ├── images/
│       │   ├── logo.png
│       │   ├── favicon.ico
│       │   └── screenshots/
│       └── js/
│           ├── custom.js
│           └── search.js
├── tests/
│   ├── test-install.sh
│   ├── test-update.sh
│   ├── test-uninstall.sh
│   └── test-upgrade.sh
└── .github/
    └── workflows/
        ├── deploy-docs.yml            # Deploy GitHub Pages
        ├── test.yml                   # Run tests
        └── release.yml                # Release automation
```

---

## 12. Updated Command Reference

```bash
# Installation
./install.sh --skill <skill-name>                    # Install single skill
./install.sh --skill <skill1> --skill <skill2>       # Install multiple skills
./install.sh --all                                   # Install all skills
./install.sh --skill <skill-name> --ide claude       # Install for specific IDE
./install.sh --skill <skill-name> --ide cursor       # Install for Cursor
./install.sh --skill <skill-name> --ide both         # Install for both (default)

# Management
./install.sh --list                                  # List available skills
./install.sh --list-installed                        # List installed skills
./install.sh --update <skill-name>                   # Update skill documentation
./install.sh --uninstall <skill-name>                # Uninstall skill
./install.sh --verify <skill-name>                   # Verify installation

# Upgrades
./install.sh --check-updates                         # Check for available updates
./install.sh --upgrade-installer                     # Upgrade the installer itself
./install.sh --upgrade <skill-name>                  # Upgrade specific skill
./install.sh --upgrade-all                           # Upgrade all skills

# Utilities
./install.sh --help                                  # Show help
./install.sh --version                               # Show version
./install.sh --verbose                               # Verbose output
./install.sh --dry-run                               # Show what would be done
./install.sh --force                                 # Force operation
./install.sh --check-prereqs                         # Check prerequisites
```

---

## 13. Updated Open Questions

### 13.1 Technical Research

**OQ-1 through OQ-4**: Claude/Cursor skill format and capabilities (see section 7.1)

### 13.2 Scope and Features

**OQ-5 through OQ-10**: Repository cloning, dependencies, customization (see section 7.2)

### 13.3 Upgrade Strategy

**OQ-11: Upgrade Frequency**
- How often should automatic update checks occur?
- Should there be configurable update channels (stable, beta)?
- Should upgrades require user confirmation by default?

**OQ-12: Breaking Changes**
- How to handle breaking changes in upgrades?
- Should there be migration scripts?
- How to communicate breaking changes to users?

**OQ-13: Rollback Strategy**
- How many previous versions to keep for rollback?
- Should rollback be automatic on failure?
- How to handle registry format changes during rollback?

### 13.4 GitHub Pages

**OQ-14: Theme Selection**
- Which Jekyll theme to use (Cayman, Just the Docs, Minimal Mistakes)?
- Should there be dark mode support?
- What level of customization is needed?

**OQ-15: Documentation Maintenance**
- Who is responsible for keeping docs updated?
- Should docs be auto-generated from code?
- How to handle versioned documentation?

**OQ-16: Community Features**
- Should there be a discussion forum on the site?
- Should there be user-submitted examples?
- How to moderate community contributions?

**OQ-17: Analytics**
- Should Google Analytics be enabled?
- What metrics should be tracked?
- Privacy considerations?

### 13.5 Documentation Requirements

**OQ-18 through OQ-20**: Specific documentation files for each skill (see section 7.6)

### 13.6 Testing and Validation

**OQ-21 through OQ-22**: Testing strategy and validation metrics (see section 7.7)

### 13.7 Maintenance and Support

**OQ-23 through OQ-25**: Update frequency, support model, versioning (see section 7.8)

### 13.8 Platform Support

**OQ-26 through OQ-27**: Operating system and shell compatibility (see section 7.9)

---

## 14. Document Control

**Document Version:** 1.0  
**Created:** 2024-03-31  
**Last Updated:** 2024-03-31  
**Status:** Draft - Pending Technical Research  

**Next Steps:**
1. Research Claude Desktop skill format and configuration
2. Research Cursor skill format and configuration
3. Determine exact documentation files to include for each skill
4. Define specific tool capabilities for each skill
5. Create prototype skill definition
6. Validate installation approach with test users
7. Select GitHub Pages theme and begin documentation
8. Set up GitHub Actions workflows

**Approval Required From:**
- Technical Lead (skill format validation)
- DevOps Team (workflow validation)
- Security Team (security review)
- Documentation Team (GitHub Pages review)

**Change Log:**
- 2024-03-31: Initial PRD created with full feature set including upgrades and GitHub Pages

---

**END OF DOCUMENT**

This PRD provides a comprehensive foundation for developing the rhel-devops-skills-cli project. Several areas require additional technical research (marked as "TBD" or in Open Questions) before implementation can begin. The document should be updated as research is completed and decisions are made.