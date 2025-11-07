#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHARTS_DIR="$ROOT_DIR/charts"
README="$ROOT_DIR/README.md"
SITE="$ROOT_DIR/public/index.html"
HEADER='| Chart | Path | Chart Version | App Version | OCI Reference |
|-------|------|---------------|-------------|---------------|'
MD_TMP=$(mktemp)
HTML_TMP=$(mktemp)
printf '%s\n' "$HEADER" > "$MD_TMP"
cat <<'HTML' > "$HTML_TMP"
        <div class="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Chart</th>
                <th>Description</th>
                <th>OCI Reference</th>
                <th>Docs</th>
              </tr>
            </thead>
            <tbody>
HTML
found=0
while IFS= read -r chart; do
  chart_yaml="$chart/Chart.yaml"
  [ -f "$chart_yaml" ] || continue
  chart_name=$(awk -F': *' '/^name:/ {print $2; exit}' "$chart_yaml")
  chart_version=$(awk -F': *' '/^version:/ {print $2; exit}' "$chart_yaml")
  app_version=$(awk -F': *' '/^appVersion:/ {print $2; exit}' "$chart_yaml")
  description=$(awk -F': *' '/^description:/ {print substr($0, index($0,$2)); exit}' "$chart_yaml")
  [ -n "$description" ] || description="$chart_name chart"
  dir_name=$(basename "$chart")
  oci_ref="oci://ghcr.io/klustrefs/charts/${dir_name}"
  doc_link="https://github.com/klustrefs/charts/tree/main/charts/${dir_name}"
  printf '| %s | [`%s`](charts/%s) | `%s` | `%s` | `%s` |\n' \
    "$chart_name" "$dir_name" "$dir_name" "$chart_version" "$app_version" "$oci_ref" >> "$MD_TMP"
  escaped_desc=${description//&/&amp;}
  escaped_desc=${escaped_desc//</&lt;}
  escaped_desc=${escaped_desc//>/&gt;}
  cat <<HTML >> "$HTML_TMP"
              <tr>
                <td><code>${dir_name}</code></td>
                <td>${escaped_desc}</td>
                <td><code>${oci_ref}</code></td>
                <td><a href="${doc_link}">Values</a></td>
              </tr>
HTML
  found=1
done < <(find "$CHARTS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
if [[ "$found" -eq 0 ]]; then
  echo "No charts found under $CHARTS_DIR" >&2
  rm -f "$MD_TMP" "$HTML_TMP"
  exit 1
fi
cat <<'HTML' >> "$HTML_TMP"
            </tbody>
          </table>
        </div>
HTML
update_section() {
  local file="$1" start="$2" end="$3" content_file="$4"
  local tmp=$(mktemp)
  awk -v start="$start" -v end="$end" -v content_file="$content_file" '
    BEGIN {
      in_section = 0
      while ((getline line < content_file) > 0) {
        if (content == "") content = line; else content = content "\n" line
      }
      close(content_file)
    }
    {
      if (index($0, start)) {
        print start
        print content
        in_section = 1
        next
      }
      if (index($0, end)) {
        print end
        in_section = 0
        next
      }
      if (!in_section) print
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}
update_section "$README" "<!-- charts-table:start -->" "<!-- charts-table:end -->" "$MD_TMP"
update_section "$SITE" "<!-- charts-table-html:start -->" "<!-- charts-table-html:end -->" "$HTML_TMP"
rm -f "$MD_TMP" "$HTML_TMP"
