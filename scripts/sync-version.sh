#!/usr/bin/env bash
# Keeps Cargo's package version in sync with the latest vX.Y.Z tag.
# Cargo needs a literal in Cargo.toml, so build.rs cannot set it itself.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

version=${ATLAS_VERSION:-}
if [[ -z $version ]]; then
	version=$(git tag --list 'v[0-9]*' --merged HEAD --sort=-version:refname 2>/dev/null | sed -n '1s/^v//p' || true)
fi
if [[ -z $version ]]; then
	version=$(git log -1 --format=%cd --date=format:0.0.%Y%m%d 2>/dev/null || true)
fi
if [[ -z $version ]]; then
	# Source archives have no git history; keep whatever Cargo.toml already has.
	version=$(awk '
		/^\[/ { package = ($0 == "[package]"); next }
		package && /^version = "/ {
			line = $0
			sub(/^version = "/, "", line)
			sub(/".*$/, "", line)
			print line
			exit
		}
	' Cargo.toml)
fi
if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]; then
	echo "sync-version: '$version' is not a Cargo-compatible version" >&2
	exit 1
fi

manifest_version=$(awk '
	/^\[/ { package = ($0 == "[package]"); next }
	package && /^version = "/ {
		line = $0
		sub(/^version = "/, "", line)
		sub(/".*$/, "", line)
		print line
		exit
	}
' Cargo.toml)
lock_version=$(awk '
	/^name = "atlas"$/ { atlas = 1; next }
	atlas && /^version = "/ {
		line = $0
		sub(/^version = "/, "", line)
		sub(/".*$/, "", line)
		print line
		exit
	}
' Cargo.lock)

if [[ $manifest_version == "$version" && $lock_version == "$version" ]]; then
	echo "$version"
	exit 0
fi

tmp=$(mktemp)
awk -v v="$version" '
	/^\[/ { package = ($0 == "[package]") }
	package && !done && /^version = "/ {
		sub(/version = "[^"]*"/, "version = \"" v "\"")
		done = 1
	}
	{ print }
' Cargo.toml > "$tmp"
cp "$tmp" Cargo.toml
rm -f "$tmp"

tmp=$(mktemp)
awk -v v="$version" '
	/^name = "atlas"$/ { atlas = 1 }
	atlas && !done && /^version = "/ {
		sub(/version = "[^"]*"/, "version = \"" v "\"")
		done = 1
		atlas = 0
	}
	{ print }
' Cargo.lock > "$tmp"
cp "$tmp" Cargo.lock
rm -f "$tmp"

echo "$version"
