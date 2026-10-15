#!/usr/bin/env bash
set -euo pipefail

echo "=== VASPBox environment check ==="

for cmd in vgdoctor vgq vgcheck mpirun taskset; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "%-12s OK  %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "%-12s MISSING\n" "$cmd"
  fi
done

echo
vgdoctor || true

echo
echo "=== Active VASP processes ==="
pgrep -a vasp || echo "No VASP processes found."
