# pattern-metadata.yaml — Validated Patterns

> Source: Validated Patterns governance documentation and reference patterns (multicloud-gitops, industrial-edge)
> Research question: RQ-6
> Note: The exact field-level schema requires inspection of upstream reference patterns. See (SCHEMA PENDING) section below.

---

## Purpose

`pattern-metadata.yaml` is the identity document for a Validated Pattern within the broader VP ecosystem. It is:

- Parsed by upstream aggregators to index the pattern in the VP catalog
- Read by CI/CD pipelines to categorize and display the pattern on [validatedpatterns.io](https://validatedpatterns.io)
- Required by the Validated Patterns governance team for any formal tier submission

**Without this file:**
- The pattern repository is invisible to the VP framework catalog
- Automated indexing systems cannot process the repository
- Submission for any tier (Sandbox, Tested, Maintained) results in immediate rejection

---

## Location

The file must be placed at the **root of the pattern repository**:

```
<pattern-root>/
├── pattern-metadata.yaml   ← here
├── values-global.yaml
├── values-hub.yaml
├── charts/
└── ...
```

---

## Known Fields (from research)

The file documents the pattern's formalized metadata for the VP ecosystem:

| Field category | Description |
|---|---|
| Display name | The human-readable name shown in the VP catalog |
| Architectural description | Summary of what the pattern deploys and why |
| Targeted enterprise use cases | The business problems the pattern solves |
| Technical prerequisites | Specific dependencies such as required vector databases (e.g. Redis, EDB Postgres) or inference providers for LLM patterns |

---

## (SCHEMA PENDING)

The exact required and optional field names with their YAML key names need to be verified by inspecting upstream reference patterns. Recommended sources:

1. [multicloud-gitops pattern-metadata.yaml](https://github.com/validatedpatterns/multicloud-gitops/blob/main/pattern-metadata.yaml)
2. [industrial-edge pattern-metadata.yaml](https://github.com/validatedpatterns/industrial-edge/blob/main/pattern-metadata.yaml)

Once inspected, update this file with:
- The complete list of YAML field keys
- Which fields are required vs optional
- Allowed values or formats for constrained fields (e.g. tier, category)

---

## What `patternizer init` Does Not Generate

`patternizer init` does **not** create `pattern-metadata.yaml`. Developers must create it manually. Its absence causes the pattern to be invisible to the VP catalog, even if the pattern deploys and runs correctly on a cluster.

If a developer intends only to run the pattern locally without contributing to the VP ecosystem, this file is technically optional. However, for any submission or distribution intent, it is mandatory.
