# Contributing

Thank you for improving KlustreFS Helm charts! This repo mirrors the contributing workflow we use across the KlustreFS projects.

## How We Work

1. **Fork & Branch** – create a topic branch (`git checkout -b feat/my-change`).
2. **Conventional Commits** – follow [conventionalcommits.org](https://www.conventionalcommits.org/) (`type(scope): summary`).
3. **Sign Off** – append a Developer Certificate of Origin sign-off to every commit (`git commit --signoff`).
4. **Docs & Tests** – update chart READMEs/values when behavior changes; add tests where possible.
5. **Preflight** – run `make verify` locally to ensure CI will pass before opening a PR.
6. **SemVer Awareness** – call out breaking changes in the PR description so we can bump the chart major version when needed.

## Tagging & Releases

Each chart is released independently using tags of the form `<chart-name>-<semver>` (for example `klustre-csi-plugin-0.1.0`). Use the Makefile helpers to keep the flow consistent:

- `make chart-release CHART=klustre-csi-plugin VERSION=0.1.0` – lint/docs/package that chart and create/push the tag (triggers CI, GitHub release, and OCI publish).
- `make chart-tag ...` / `make chart-tag-push ...` – create or push a per-chart tag manually.
- `make chart-tag-delete ...` / `make chart-tag-repush ...` – remove or redo a chart-specific tag if CI needs to be rerun.

Global repo tags (rare) still work via `make release VERSION=vX.Y.Z`, but in most cases you should tag charts individually so the automation only rebuilds what changed.

## Development

### Prerequisites

- Helm 3.8+ installed and on your `PATH`.
- Go toolchain (1.21+) for installing `helm-docs`.
- Optional: Docker if you plan to push charts from the publish workflow locally.

Run once to install local tooling:

```bash
make deps
```

### Common Tasks

```bash
make docs     # regenerate chart README files via helm-docs
make lint     # run helm lint --strict across charts/
make package  # docs + lint + produce dist/<chart>.tgz
make test     # render-time unit tests via helm-unittest
make validate # render & schema-validate manifests via kubeconform
make schema   # build/update values.schema.json via helm-schema
make golden   # regenerate golden helm template outputs per scenario
make verify   # docs + lint + tests + validation + schema + golden
```

`make docs` must leave the tree clean—commit any generated README changes with your PR.

### Questions & Issues

- File bugs or feature requests in [klustrefs/charts issues](https://github.com/klustrefs/charts/issues).
- For deployment or chart questions, open a discussion or reach us via the community channels listed on [klustrefs.io/charts](https://klustrefs.io/charts/).
