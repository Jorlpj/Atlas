# Map state pages

The map pages document the playbook's configured behavior from source at the repository revision they cite. Start with [`playbook.conf`](../playbook-conf.md) for setup choices and supported-build declarations, then [`custom.yml`](../custom.md) for root execution order. Follow its links to the child task areas, then the tweak root and group pages for individual conditions and actions. A script or module description is scoped to its call site: included files can expose behavior without the root playbook invoking it. Citations use repository-relative `path:line` references.

## Current-state views

- [Store, Xbox, AppX and Windows Update servicing](store-xbox-servicing.md) collects the mapped actions touching those areas, with conditions and revert notes.
- [Revert coverage by map area](revert-coverage.md) records explicit counterpart controls and gaps in the inspected playbook configuration.

The coverage page describes whether a counterpart exists; it does not promise restoration of the exact prior state. For the underlying source details, use the linked area page and reopen its `path:line` citations. These pages summarize the map; they do not replace the cited source or establish runtime outcomes beyond it.
