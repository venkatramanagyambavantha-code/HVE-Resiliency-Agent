#!/usr/bin/env bash
#
# Installs the HVE Resiliency Copilot skills, prompts, and instructions into the current repository.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.sh | bash -s -- --ref v1.0 --force
#
# Flags:
#   --ref <ref>          Branch, tag, or commit to install from (default: main)
#   --destination <dir>  Target repo root (default: current working directory)
#   --repo <owner/name>  Source repository (default: christopherromero/HVE-Resiliency)
#   --force              Overwrite existing files without prompting
#   --include "a b c"    Space-separated subfolders of .github to install
#                        (default: "skills prompts instructions")

set -euo pipefail

REF="main"
DESTINATION="$(pwd)"
REPO="christopherromero/HVE-Resiliency"
FORCE=0
INCLUDE=(skills prompts instructions)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)         REF="$2"; shift 2 ;;
    --destination) DESTINATION="$2"; shift 2 ;;
    --repo)        REPO="$2"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    --include)     # shellcheck disable=SC2206
                   INCLUDE=($2); shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

echo ""
echo "HVE Resiliency installer  (${REPO}@${REF})"
echo "Destination: ${DESTINATION}"
echo "Sections   : ${INCLUDE[*]}"
echo ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ZIP_URL="https://codeload.github.com/${REPO}/zip/refs/heads/${REF}"
echo "Downloading ${ZIP_URL} ..."
if ! curl -fsSL "$ZIP_URL" -o "$TMP/archive.zip"; then
  ZIP_URL="https://codeload.github.com/${REPO}/zip/refs/tags/${REF}"
  echo "  refs/heads not found, trying refs/tags: ${ZIP_URL}"
  curl -fsSL "$ZIP_URL" -o "$TMP/archive.zip"
fi

echo "Extracting ..."
( cd "$TMP" && unzip -q archive.zip )

SRC_ROOT="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d ! -name 'archive.zip*' | head -n 1)"
SRC_GITHUB="${SRC_ROOT}/.github"
if [[ ! -d "$SRC_GITHUB" ]]; then
  echo "No .github folder found in the downloaded archive: $SRC_GITHUB" >&2
  exit 1
fi

DST_GITHUB="${DESTINATION}/.github"
mkdir -p "$DST_GITHUB"

copied=0
skipped=0
for section in "${INCLUDE[@]}"; do
  src="${SRC_GITHUB}/${section}"
  if [[ ! -d "$src" ]]; then
    echo "  Skipping ${section}: not present in source."
    continue
  fi
  dst="${DST_GITHUB}/${section}"
  echo "Installing .github/${section} ..."

  while IFS= read -r -d '' file; do
    rel="${file#${src}/}"
    target="${dst}/${rel}"
    mkdir -p "$(dirname "$target")"

    if [[ -e "$target" && $FORCE -eq 0 ]]; then
      if cmp -s "$file" "$target"; then
        skipped=$((skipped + 1))
        continue
      fi
      printf "Overwrite %s? [y/N/a(ll)] " "$target"
      read -r answer < /dev/tty || answer=""
      case "${answer,,}" in
        a) FORCE=1 ;;
        y) ;;
        *) skipped=$((skipped + 1)); continue ;;
      esac
    fi
    cp -f "$file" "$target"
    copied=$((copied + 1))
  done < <(find "$src" -type f -print0)
done

echo ""
echo "Installed: ${copied} file(s) copied, ${skipped} skipped."
echo ""
echo "Next steps:"
echo "  1. Reload VS Code (Developer: Reload Window) so Copilot Chat re-indexes the new files."
echo "  2. Install the HVE Core VS Code extension if you have not already:"
echo "     https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core"
echo "  3. In Copilot Chat type \"/\" to see the new commands:"
echo "     /hve-resiliency-research"
echo "     /hve-resiliency-workitem-export"
echo "     /hve-resiliency-workitem-import"
echo "     /hve-resiliency-workitem-jira-import"
echo "  4. Commit the new .github/ files so your team gets the same workflow."
echo ""
