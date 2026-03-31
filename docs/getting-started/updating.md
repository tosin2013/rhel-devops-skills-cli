---
title: Updating Skills
parent: Getting Started
nav_order: 2
---

# Updating Skills

Skills are backed by upstream Git repositories. When those repositories update, you can pull the latest documentation into your installed skills.

## Check for Updates

```bash
./install.sh check-updates
```

This compares the stored commit hash in your registry with the latest commit on the upstream branch using `git ls-remote`.

## Update a Single Skill

```bash
./install.sh update --skill agnosticd
```

## Update All Skills

```bash
./install.sh update --all
```

## Force Update

If you want to re-fetch even when the commit hash matches:

```bash
./install.sh update --skill agnosticd --force
```

## Automatic Update Checks

By default, the installer checks for updates when you run `install`. You can disable this:

```bash
./install.sh install --skill agnosticd --no-auto-check
```

## Upgrade the Installer Itself

```bash
./install.sh upgrade-installer
```

This checks for new releases on GitHub and self-updates `install.sh` and `lib/` while backing up the current version.
