# KlustreFS Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/klustre-csi-plugin)](https://artifacthub.io/packages/search?repo=klustre-csi-plugin)
[![CI](https://github.com/klustrefs/charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/klustrefs/charts/actions/workflows/ci.yaml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/klustrefs/charts?sort=semver)](https://github.com/klustrefs/charts/releases)
[![OCI Registry](https://img.shields.io/badge/helm%20oci-ghcr.io%2Fklustrefs%2Fcharts-0F1689?logo=helm&logoColor=white)](https://klustrefs.io/charts/)
[![Docs](https://img.shields.io/badge/docs-klustrefs.io%2Fcharts-1F6FEB?logo=readthedocs&logoColor=white)](https://klustrefs.io/charts/)

Helm charts for the KlustreFS platform. All artifacts are published as OCI packages under `oci://ghcr.io/klustrefs/charts` and surfaced on the static landing page at [klustrefs.io/charts](https://klustrefs.io/charts/) (source in `public/`).

## Charts

<!-- charts-table:start -->
| Chart | Path | Chart Version | App Version | OCI Reference |
|-------|------|---------------|-------------|---------------|
| klustre-csi-plugin | [`klustre-csi-plugin`](charts/klustre-csi-plugin) | `0.1.1` | `0.1.1` | `oci://ghcr.io/klustrefs/charts/klustre-csi-plugin` |
<!-- charts-table:end -->

Each chart directory contains its own README and default values. Run `helm show all oci://ghcr.io/klustrefs/charts/<chart>` for published metadata.

## Quickstart

> Prerequisites: Helm 3.8+ (for OCI support) and a GitHub token with the `read:packages` scope.

1. **Log in to GHCR**

   ```bash
   helm registry login ghcr.io -u <github-username>
   ```

2. **Discover charts & versions**
   - Browse https://klustrefs.io/charts/ for the current catalog.
   - Or pull metadata for a specific chart:

     ```bash
     REGISTRY=oci://ghcr.io/klustrefs/charts
     helm show chart "$REGISTRY/<chart-name>" --version <version>
     helm show values "$REGISTRY/<chart-name>" --version <version>
     ```

3. **Install any chart**

   ```bash
   helm upgrade --install <release-name> \
     oci://ghcr.io/klustrefs/charts/<chart-name> \
     --version <version> \
     --namespace <namespace> \
     --create-namespace
   ```

   Example (Klustre CSI plugin):

   ```bash
   helm upgrade --install klustre-csi \
     oci://ghcr.io/klustrefs/charts/klustre-csi-plugin \
     --version 0.1.0 \
     --namespace klustre-system \
     --create-namespace
   ```

4. **Inspect packaged artifacts (optional)**

   ```bash
   helm pull "$REGISTRY/<chart-name>" --version <version>
   tar -tf <chart-name>-<version>.tgz
   ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build/lint instructions, helm-unittest guidance, schema validation notes (via [`helm-schema`](https://github.com/dadav/helm-schema)), golden render generation, container image workflows, command-line argument reference, and contribution guidelines. Run `make verify` (docs + lint + tests + validate + schema + golden) locally before opening a PR.

## License

- Charts and supporting infrastructure: [Apache-2.0](LICENSE).
- Static site assets under `public/`: [CC-BY-4.0](public/LICENSE).
