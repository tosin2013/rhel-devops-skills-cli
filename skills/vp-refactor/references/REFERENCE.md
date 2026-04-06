# Validated Pattern Refactor Documentation References

## Reference Documents

| File | Description | Source | Research Question | Status |
|------|-------------|--------|-------------------|--------|
| `values-files-guide.md` | Mandatory fields for values-global.yaml and values-<cluster>.yaml, clusterGroupName routing, three-block dependency chain | [VP Framework](https://validatedpatterns.io/learn/vp_openshift_framework/) | RQ-1 | Created |
| `operator-discovery.md` | Catalog source comparison, `oc get packagemanifests` discovery workflow, channel and startingCSV lookup | [ClusterGroup Values](https://validatedpatterns.io/learn/clustergroup-in-values-files/) | RQ-2 | Created |
| `charts-directory.md` | Minimum Helm chart anatomy, Chart.yaml required fields, applications-block to ArgoCD Application CR field mapping | [VP Structure](https://validatedpatterns.io/learn/vp_structure_vp_pattern/) | RQ-3 | Created |
| `secrets-management.md` | `--with-secrets` architectural impact, Vault+ESO flow, values-secret.yaml mandatory path | [Secrets Management](https://validatedpatterns.io/learn/secrets-management-in-the-validated-patterns-framework/) | RQ-4 | Created |
| `vp-operator-guide.md` | CLI vs VP Operator comparison, three Operator form fields, known limitations | [VP Operator Guide](https://validatedpatterns.io/learn/using-validated-pattern-operator/) | RQ-5 | Created |
| `pattern-metadata.md` | Purpose, location, known fields — schema field-level detail still pending upstream inspection | Reference patterns (multicloud-gitops, industrial-edge) | RQ-6 | Partial — schema pending |
| `imperative-jobs.md` | CronJob architecture, playbook directory, YAML list requirement, 10-min schedule, idempotency mandate, configurable options | [ClusterGroup Values](https://validatedpatterns.io/learn/clustergroup-in-values-files/) | RQ-8 | Created |

## External Resources (Available Now)

These upstream sources are publicly accessible and can be referenced directly:

| Resource | URL | Covers |
|----------|-----|--------|
| VP Framework Structure | https://validatedpatterns.io/learn/vp_openshift_framework/ | Directory layout, charts/, values- files |
| ClusterGroup in Values Files | https://validatedpatterns.io/learn/clustergroup-in-values-files/ | Subscriptions, applications, namespaces, imperative |
| Structuring a Validated Pattern | https://validatedpatterns.io/learn/vp_structure_vp_pattern/ | Best practices, Helm migration, operator framework |
| Secrets Management | https://validatedpatterns.io/learn/secrets-management-in-the-validated-patterns-framework/ | Vault, ESO, values-secret.yaml |
| Using the VP Operator | https://validatedpatterns.io/learn/using-validated-pattern-operator/ | Operator install, Create Pattern form |
| Pattern Tier Requirements | https://validatedpatterns.io/learn/about-pattern-tiers-types/ | Sandbox/Tested/Maintained criteria |
| Contributing a Pattern | https://validatedpatterns.io/contribute/creating-a-pattern/ | Refactoring existing deployments into VP framework |
| Patternizer README | https://github.com/validatedpatterns/patternizer | Generated files, init --with-secrets, upgrade |
| Multicloud GitOps (reference pattern) | https://github.com/validatedpatterns/multicloud-gitops | Real-world example of complete pattern structure |

## Source Repository

- **Upstream Patternizer**: https://github.com/validatedpatterns/patternizer
- **Fork**: https://github.com/tosin2013/patternizer
- **Validated Patterns Docs**: https://validatedpatterns.io/
- **To be fetched**: At research completion via `./install.sh --update vp-refactor`

## Updating

```bash
./install.sh --update vp-refactor
```
