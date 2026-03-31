# Showroom Documentation References

This directory contains documentation fetched from the Showroom ecosystem repositories.

## Available Documents

| File | Description | Source Repository | Source Path |
|------|-------------|-------------------|-------------|
| `showroom-deployer-README.adoc` | Helm chart deployment guide, namespace creation, install procedures | [rhpds/showroom-deployer](https://github.com/rhpds/showroom-deployer) | `README.adoc` |
| `showroom-template-README.adoc` | Content authoring guide, Antora structure, local preview | [rhpds/showroom_template_default](https://github.com/rhpds/showroom_template_default) | `README.adoc` |
| `ocp4-workload-showroom-README.adoc` | AgnosticD workload role configuration, terminal types, Helm chart selection | [agnosticd/core_workloads](https://github.com/agnosticd/core_workloads) | `roles/ocp4_workload_showroom/README.adoc` |

## External Resources

- **Showroom Deployer Helm Chart**: https://github.com/rhpds/showroom-deployer
- **Default Content Template**: https://github.com/rhpds/showroom_template_default
- **AgnosticD Workload Role**: https://github.com/agnosticd/core_workloads/tree/main/roles/ocp4_workload_showroom
- **Terminal Container Images**: https://github.com/rhpds/openshift-showroom-terminal-image
- **Antora Documentation**: https://docs.antora.org/

## Source Repositories

- **Primary**: https://github.com/rhpds/showroom-deployer
- **Content Template**: https://github.com/rhpds/showroom_template_default
- **Branch**: main
- **Fetched**: At install time via `./install.sh --skill showroom`

## Updating

```bash
./install.sh --update showroom
```
