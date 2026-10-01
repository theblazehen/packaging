#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
    echo "Usage: $0 PACKAGE_DIR" >&2
    exit 2
fi

package_dir=$(cd -- "$1" && pwd)
cd "$package_dir"

if [[ ! -f PKGBUILD ]]; then
    echo "ERROR: PKGBUILD not found in $package_dir" >&2
    exit 1
fi

echo "--- Installing AUR-only dependencies ---"
all_deps=()
while IFS= read -r dep; do
    dep="${dep%%[>=<]*}"
    [[ -z "$dep" ]] && continue
    if ! pacman -Si "$dep" &>/dev/null && ! pacman -Qi "$dep" &>/dev/null; then
        all_deps+=("$dep")
    fi
done < <(
    bash -c 'source "$1" && printf "%s\n" "${depends[@]}" "${makedepends[@]}" "${checkdepends[@]}"' -- "$package_dir/PKGBUILD"
)

if [[ ${#all_deps[@]} -gt 0 ]]; then
    echo "AUR deps to install: ${all_deps[*]}"
    if ! command -v yay &>/dev/null; then
        echo "ERROR: AUR dependencies require yay: ${all_deps[*]}" >&2
        exit 1
    fi
    yay -S --noconfirm --needed "${all_deps[@]}"
else
    echo "No AUR-only dependencies found"
fi

echo "--- Building package ---"
makepkg -sf --noconfirm

echo "--- Generating .SRCINFO ---"
srcinfo=$(mktemp .SRCINFO.XXXXXX)
trap 'rm -f -- "$srcinfo"' EXIT
makepkg --printsrcinfo > "$srcinfo"
mv -- "$srcinfo" .SRCINFO
