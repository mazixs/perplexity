# Native Test Build

`native-build/build.sh` creates a self-contained test bundle that includes:

- either the repository app tree plus the locally installed Electron runtime, or a local AppImage as an offline source
- production `node_modules` in `repo` mode
- default config from `aur/default.conf`
- an isolated `state/` directory so tests do not touch the user's normal `~/.config`

## Output

The build produces a single executable installer:

```bash
native-build/dist/perplexity-native-arch-x86_64-<version>.run
```

Running the installer extracts the portable test build into the target directory and prints the launch command.

## Usage

```bash
./native-build/build.sh
./native-build/dist/perplexity-native-arch-x86_64-1.6.0.run --target /tmp/perplexity-test
```

Useful flags:

- `--source auto|repo|appimage`: choose where the bundle is assembled from
- `--appimage /path/to/Perplexity-x.y.z-x86_64.AppImage`: override the local AppImage path
- `--electron-bin /path/to/electron`: use a specific Electron wrapper instead of `$(command -v electron)`
- `--skip-npm-install`: reuse the existing app tree without running `npm ci --omit=dev`

## Notes

- `auto` mode prefers the local AppImage when `src/node_modules` is not available, which makes offline builds possible.
- In `appimage` mode the bundle contains the extracted AppImage runtime and launches it with an isolated `--user-data-dir`.
- In `repo` mode the bundle includes the Electron runtime directory from `/usr/lib/<electron-wrapper-name>`.
- System desktop libraries are still loaded from the host OS, so this is intended for local testing on a compatible Linux environment, not for universal redistribution.
- The installed launcher keeps app state under `<install-dir>/state/` by default.
