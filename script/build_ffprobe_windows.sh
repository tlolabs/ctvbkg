#!/usr/bin/env bash
# Run inside the matching MSYS2 UCRT64 or CLANGARM64 shell.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=9.0.2
EXPECTED_SHA256=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
ARCHIVE="$ROOT_DIR/target/ffmpeg-$VERSION.tar.xz"
OUTPUT_DIR="${1:-$ROOT_DIR/dist/ffprobe-windows}"
mkdir -p "$ROOT_DIR/target" "$OUTPUT_DIR"
BUILD_ROOT="$(mktemp -d)"
trap 'rm -rf "$BUILD_ROOT"' EXIT
if [[ ! -f "$ARCHIVE" ]]; then
  curl --fail --location --silent --show-error "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz" --output "$ARCHIVE"
fi
test "$(sha256sum "$ARCHIVE" | cut -d' ' -f1)" = "$EXPECTED_SHA256"
tar -xf "$ARCHIVE" -C "$BUILD_ROOT"
mkdir "$BUILD_ROOT/build"
cd "$BUILD_ROOT/build"
if [[ "${MSYSTEM:-}" == CLANGARM64 ]]; then
  ARCH=aarch64
  COMPILER=clang
else
  ARCH=x86_64
  COMPILER=gcc
fi
"$BUILD_ROOT/ffmpeg-$VERSION/configure" \
  --target-os=mingw32 --arch="$ARCH" --cc="$COMPILER" --extra-ldflags=-static \
  --disable-shared --enable-static --disable-asm --disable-autodetect \
  --disable-gpl --disable-nonfree --disable-network --disable-doc \
  --disable-programs --enable-ffprobe --disable-everything \
  --enable-demuxer=mpegps --enable-parser=mpegvideo \
  --enable-decoder=mpeg2video --enable-protocol=file
make -j4 ffprobe.exe
cp ffprobe.exe "$OUTPUT_DIR/ffprobe.exe"
"$OUTPUT_DIR/ffprobe.exe" -L > "$OUTPUT_DIR/FFmpeg-LICENSE.txt"
"$OUTPUT_DIR/ffprobe.exe" -version > "$OUTPUT_DIR/FFmpeg-BUILD.txt"
cp "$ARCHIVE" "$OUTPUT_DIR/ffmpeg-$VERSION-source.tar.xz"
if grep -q 'GNU General Public License' "$OUTPUT_DIR/FFmpeg-LICENSE.txt"; then
  echo 'Expected an LGPL-only ffprobe build' >&2
  exit 1
fi
