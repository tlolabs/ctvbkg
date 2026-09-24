#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH="$(uname -m)"
if [[ "$ARCH" != x86_64 && "$ARCH" != aarch64 ]]; then
  echo "Unsupported Linux architecture: $ARCH" >&2
  exit 1
fi
: "${APPIMAGETOOL:?Set APPIMAGETOOL to an appimagetool executable for this architecture}"
PROBE_DIR="$ROOT_DIR/dist/ffprobe-linux-$ARCH"
"$ROOT_DIR/script/build_ffprobe_linux.sh" "$PROBE_DIR"
cargo build --manifest-path "$ROOT_DIR/native/linux/Cargo.toml" --release
APPDIR="$ROOT_DIR/dist/ChabotBackgrounder-$ARCH.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/glib-2.0/schemas"
cp "$ROOT_DIR/native/linux/target/release/chabot-backgrounder-linux" "$APPDIR/usr/bin/chabot-backgrounder"
cp "$PROBE_DIR/ffprobe" "$APPDIR/usr/bin/"
cp "$PROBE_DIR/FFmpeg-LICENSE.txt" "$PROBE_DIR/FFmpeg-BUILD.txt" "$PROBE_DIR/ffmpeg-9.0.2-source.tar.xz" "$APPDIR/usr/share/"
cp /usr/share/glib-2.0/schemas/gschemas.compiled "$APPDIR/usr/share/glib-2.0/schemas/"
python3 "$ROOT_DIR/script/bundle_linux_deps.py" "$APPDIR" "$APPDIR/usr/bin/chabot-backgrounder" "$APPDIR/usr/bin/ffprobe"
cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GSETTINGS_SCHEMA_DIR="$HERE/usr/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$HERE/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
exec "$HERE/usr/bin/chabot-backgrounder" "$@"
RUN
chmod +x "$APPDIR/AppRun"
cat > "$APPDIR/chabot-backgrounder.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Chabot News Backgrounder
Exec=chabot-backgrounder
Icon=chabot-backgrounder
Categories=AudioVideo;Video;
DESKTOP
cat > "$APPDIR/chabot-backgrounder.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<rect x="8" y="8" width="112" height="112" rx="24" fill="#0e2443"/>
<path d="M36 30v68l58-34z" fill="#f0f4fa"/>
</svg>
SVG
OUTPUT="$ROOT_DIR/dist/ChabotBackgrounder-linux-$ARCH.AppImage"
ARCH="$ARCH" "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
echo "Built $OUTPUT"
