#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 SOURCE_DIR AUR_REPOSITORY" >&2
    exit 2
fi

source_dir=$(cd -- "$1" && pwd)
destination=$(cd -- "$2" && pwd)
manifest="$source_dir/.aur-files"

if [[ ! -f "$manifest" ]]; then
    echo "ERROR: .aur-files not found in $source_dir" >&2
    exit 1
fi

if ! git -C "$destination" rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: $destination is not a Git repository" >&2
    exit 1
fi

declare -A manifest_files=()
declare -a files=()
while IFS= read -r file || [[ -n "$file" ]]; do
    [[ -z "$file" || "$file" == \#* ]] && continue

    case "$file" in
        /|.|..|../*|*/..|*/../*|.git|.git/*|*/.git|*/.git/*)
            echo "ERROR: Unsafe path in .aur-files: '$file'" >&2
            exit 1
            ;;
    esac

    if [[ ! -e "$source_dir/$file" && ! -L "$source_dir/$file" ]]; then
        echo "ERROR: File '$file' listed in .aur-files does not exist" >&2
        exit 1
    fi

    files+=("$file")
    manifest_files["$file"]=1
done < "$manifest"

while IFS= read -r -d '' tracked; do
    if [[ -z "${manifest_files[$tracked]+present}" ]]; then
        rm -f -- "$destination/$tracked"
        echo "Removed stale tracked file: $tracked"
    fi
done < <(git -C "$destination" ls-files -z)

for file in "${files[@]}"; do
    target="$destination/$file"
    mkdir -p -- "$(dirname -- "$target")"
    cp -aT -- "$source_dir/$file" "$target"
    echo "Exported: $file"
done
