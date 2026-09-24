# Chabot News Backgrounder

A local desktop utility for collecting CNN MPG footage and preparing the 14 Chabot News background Comps. Comps 1 and 6 are reserved; the app fills Comps 2–16 except 6 with at least **10:05** of whole clips each.

## Workflow

1. Open the app and choose the folder receiving CNN `.mpg` downloads. Only MPG files at the folder's top level are counted. A `#WORK` temporary file, a recently changing file, and nested exports are ignored.
2. The main window and optional floating panel count down from **141:10**. The app shows **Ready** only after it has found a valid assignment of unique clips to all 14 Comps. It sends one desktop notification on the transition to Ready.
3. Click **Build Comp Folders**. The app rechecks every source file, then creates a dated `Chabot News Comps ...` directory inside the chosen folder. Selected clips move into `Comp 2` through `Comp 16` (skipping 6) with random eight-digit filenames. Stable unused clips, including unreadable MPGs, move into `Unused`. Active downloads remain at the top level.
4. Import the Comp folders into Premiere Pro. `manifest.csv` records every move, including original CNN filenames when an existing `rename-map-*.csv` supplies them.

Exact byte-for-byte duplicate files are removed automatically after hash and byte comparison. The app keeps a dated `.backgrounder-duplicates.log` in the watched folder. Similar footage with different bytes is not identified yet. The app does not split or transcode clips.

## Source layout

- `crates/backgrounder-core`: Rust watcher, probing, duplicate handling, allocation, recovery journal, and versioned C ABI.
- `native/macos`: SwiftUI app with AppKit floating panel.
- `native/windows`: WinUI 3 app, unpackaged and self-contained.
- `native/linux`: GTK4 app.
- `script`: local run and release helpers.

The engine bundles or invokes `ffprobe` to read video duration. Release packages must include an architecture-matched `ffprobe` and the FFmpeg license/source notice corresponding to the exact binary build. The bundled probe is a separate executable; the app does not link FFmpeg into its Rust engine.

## Development

```sh
cargo test -p backgrounder-core
cargo run -p backgrounder-core --bin backgrounder-inspect -- "CNN VIdeos" ffprobe
./script/build_and_run.sh
```

`backgrounder-inspect` is read-only. It does not delete duplicates or move media. The Mac run script uses full Xcode if installed at `/Applications/Xcode.app`, stages a real `.app` bundle under `dist/`, and launches it.

On Linux, install GTK4 development libraries and run `cargo run --manifest-path native/linux/Cargo.toml`. On Windows, build in Visual Studio with the .NET 8 SDK, then run the Windows release script described below.

## Release targets

| System | Architectures | Initial package |
| --- | --- | --- |
| macOS 13+ | x86-64 + ARM64 | Universal signed and notarized DMG |
| Windows 10/11 | x64, ARM64 | Separate unsigned self-contained ZIPs |
| Linux | x86-64, ARM64 | Separate AppImages |

Windows signing can be added to CI when a publicly trusted signing service or certificate is available. The Linux overlay requests topmost placement on X11. Wayland may not keep it above all other applications; the window remains movable, and the main window and notification remain available.

## Packaging

The workflow in `.github/workflows/build.yml` prepares unsigned macOS and Windows packages plus Linux AppImages on native x86-64 and ARM64 runners. It runs the Rust tests on each system, builds a matching LGPL-only `ffprobe` from the pinned FFmpeg 9.0.2 source, and includes its license, build details, and source archive. Windows downloads are ZIPs containing the WinUI 3 and .NET runtimes; users extract the full ZIP before launching the app. The Linux AppImage uses GTK4 from the build environment and includes its linked libraries, so it targets distributions compatible with Ubuntu 24.04 or newer.

For a local Mac release, run `./script/release_macos.sh --sign-only` with `APPLE_DEVELOPER_ID` set to the Developer ID Application identity. The signed DMG is the input to Encap, which handles notarization for distribution. The script verifies both slices of the app, engine, and probe before signing. `./script/release_macos.sh --unsigned` produces a development DMG. A direct `notarytool` path remains available through `./script/release_macos.sh signed` if needed.

The Windows CI step runs `build_ffprobe_windows.sh` in the matching MSYS2 UCRT64 or CLANGARM64 shell, then `release_windows.ps1 -Architecture x64` or `arm64`. The Linux step runs `release_linux.sh` with `APPIMAGETOOL` pointing to an architecture-matched appimagetool. The `ffprobe` source archive and build record are included for license compliance. Windows code signing requires a later, trusted signing identity; a CI certificate made solely for the workflow would not establish publisher trust.

## Recovery

Build moves are recorded in `journal.json` before any source clip is moved. An interrupted build leaves a `.building-*` directory. The next app launch restores moved clips to the download folder and removes that staging directory. If recovery cannot safely restore a file, the app stops and reports the staging directory path for manual review.
