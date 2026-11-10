#!/bin/bash
# Points astra-atlas and astra-atlas-bin at a published release, refreshes
# their checksums and regenerates every package's .SRCINFO.
#
#   packaging/update.sh 1.4.0
#
# Run it after the release workflow has uploaded the tarball and binary for
# that tag, then copy each folder into its AUR clone and push.
set -euo pipefail

cd "$(dirname "$0")"
version=${1:?usage: update.sh <version, without the leading v>}

for pkg in astra-atlas astra-atlas-bin; do
	sed -i -e "s/^pkgver=.*/pkgver=${version}/" -e "s/^pkgrel=.*/pkgrel=1/" "${pkg}/PKGBUILD"
	(cd "${pkg}" && updpkgsums && makepkg --printsrcinfo > .SRCINFO)
done

(cd astra-atlas-git && makepkg --printsrcinfo > .SRCINFO)

# updpkgsums leaves the downloads behind
rm -f astra-atlas/*.tar.gz astra-atlas-bin/astra-atlas-v* astra-atlas-bin/atlas-* astra-atlas-bin/LICENSE-*
