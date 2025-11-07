#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHARTS_DIR="$ROOT_DIR/charts"
README="$ROOT_DIR/README.md"
HEADER='| Chart | Path | Chart Version | App Version | OCI Reference |
|-------|------|---------------|-------------|---------------|'
TABLE_FILE=$(mktemp)
printf '%s\n' "$HEADER" > "$TABLE_FILE"
found=0
while IFS= read -r chart; do
  chart_yaml="$chart/Chart.yaml"
  [ -f "$chart_yaml" ] || continue
  chart_name=$(awk -F': ' '/^name:/ {print $2; exit}' "$chart_yaml")
  chart_version=$(awk -F': ' '/^version:/ {print $2; exit}' "$chart_yaml")
  app_version=$(awk -F': ' '/^appVersion:/ {print $2; exit}' "$chart_yaml")
  dir_name=$(basename "$chart")
  oci_ref="oci://ghcr.io/klustrefs/charts/${dir_name}"
  printf '| %s | [`%s`](charts/%s) | `%s` | `%s` | `%s` |\n' \
    "$chart_name" "$dir_name" "$dir_name" "$chart_version" "$app_version" "$oci_ref" >> "$TABLE_FILE"
  found=1
done < <(find "$CHARTS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
if [[ "$found" -eq 0 ]]; then
  echo "No charts found under $CHARTS_DIR" >&2
  rm -f "$TABLE_FILE"
  exit 1
fi
awk -v start='<!-- charts-table:start -->' -v end='<!-- charts-table:end -->' -v tablefile="$TABLE_FILE" '
  BEGIN {
    table = ""
    while ((getline line < tablefile) > 0) {
      if (table != "") table = table "\n"
      table = table line
    }
    close(tablefile)
  }
  {
    if ($0 ~ start) {
      print start
      print table
      in_section = 1
      next
    }
    if ($0 ~ end) {
      print end
      in_section = 0
      next
    }
    if (!in_section) print
  }
' "$README" > "$README.tmp"
mv "$README.tmp" "$README"
rm -f "$TABLE_FILE"
