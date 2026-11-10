# AUR packaging

The three Arch User Repository packages for Atlas, one folder each, laid out the
way their AUR git repositories are (a `PKGBUILD` and its `.SRCINFO`).

| Package | Builds from | Notes |
| --- | --- | --- |
| `astra-atlas` | the release tarball (`astra-atlas-<version>.tar.gz`) | Cargo build, `cargo test` in `check()` |
| `astra-atlas-git` | `main` on GitHub | version from `git describe` |
| `astra-atlas-bin` | the release binary (`astra-atlas-v<version>`) | x86_64 only; desktop entry, icon and licence from the tag |

All three install the same files (`/usr/bin/atlas`, the desktop entry and the
icon), so they conflict with each other; `-git` and `-bin` provide `astra-atlas`.

## Releasing

1. Tag the release (`git tag v1.4.0 && git push origin v1.4.0`) and let the
   Release workflow upload the tarball and binary.
2. Point the stable and binary packages at it, refresh checksums and every
   `.SRCINFO`:

   ```bash
   packaging/update.sh 1.4.0
   ```

3. Copy each folder's `PKGBUILD` and `.SRCINFO` into its AUR clone
   (`ssh://aur@aur.archlinux.org/<package>.git`), commit and push.

To try a package locally: `cd packaging/astra-atlas-git && makepkg -si`.
