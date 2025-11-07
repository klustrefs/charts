# KlustreFS Helm Charts

[![CI](https://github.com/klustrefs/charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/klustrefs/charts/actions/workflows/ci.yaml)
[![Publish](https://github.com/klustrefs/charts/actions/workflows/publish.yml/badge.svg)](https://github.com/klustrefs/charts/actions/workflows/publish.yml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/klustrefs/charts?sort=semver)](https://github.com/klustrefs/charts/releases)

Helm charts for the KlustreFS platform. All artifacts are published as OCI packages under `oci://ghcr.io/klustrefs/charts` and surfaced on the static landing page at [klustrefs.io/charts](https://klustrefs.io/charts/) (source in `public/`).

## Charts

<!-- charts-table:start -->
| Chart | Path | Chart Version | App Version | OCI Reference |
|-------|------|---------------|-------------|---------------|
| klustre-csi-plugin | [`klustre-csi-plugin`](charts/klustre-csi-plugin) | `0.1.0` | `0.1.1` | `oci://ghcr.io/klustrefs/charts/klustre-csi-plugin` |
<!-- charts-table:end -->

Each chart directory contains its own README and default values. Run `helm show all oci://ghcr.io/klustrefs/charts/<chart>` for published metadata.

## Quickstart

```bash
# 1. Authenticate (requires GitHub token with read:packages)
helm registry login ghcr.io -u <github-username>

# 2. Pull a chart
REGISTRY=oci://ghcr.io/klustrefs/charts
helm pull "$REGISTRY/<chart-name>" --version <version>

# 3. Install the Klustre CSI plugin
helm install klustre-csi oci://ghcr.io/klustrefs/charts/klustre-csi-plugin \
  --version 0.1.0 \
  --namespace klustre-system \
  --create-namespace
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build/lint instructions, container image workflows, command-line argument reference, and contribution guidelines.

## License

- Charts and supporting infrastructure: [Apache-2.0](LICENSE).
- Static site assets under `public/`: [CC-BY-4.0](public/LICENSE).
