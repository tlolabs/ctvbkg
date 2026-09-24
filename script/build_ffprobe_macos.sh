#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=9.0.2
EXPECTED_SHA256=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
ARCHIVE="$ROOT_DIR/target/ffmpeg-$VERSION.tar.xz"
OUTPUT="$ROOT_DIR/dist/ffprobe-universal"
mkdir -p "$ROOT_DIR/target" "$ROOT_DIR/dist"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/chabot-ffmpeg.XXXXXX")"
trap 'rm -rf "$BUILD_ROOT"' EXIT
SOURCE="$BUILD_ROOT/ffmpeg-$VERSION"

if [[ ! -f "$ARCHIVE" ]]; then
  curl --fail --location --silent --show-error "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz" --output "$ARCHIVE"
fi
ACTUAL_SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "FFmpeg source checksum mismatch" >&2
  exit 1
fi
tar -xf "$ARCHIVE" -C "$BUILD_ROOT"

for pair in "arm64:aarch64" "x86_64:x86_64"; do
  DARWIN_ARCH="${pair%%:*}"
  FFMPEG_ARCH="${pair##*:}"
  BUILD="$BUILD_ROOT/build-$DARWIN_ARCH"
  mkdir -p "$BUILD"
  cd "$BUILD"
  "$SOURCE/configure" \
    --target-os=darwin --arch="$FFMPEG_ARCH" --enable-cross-compile \
    --cc="clang -arch $DARWIN_ARCH" \
    --extra-cflags="-arch $DARWIN_ARCH -mmacosx-version-min=13.0" \
    --extra-ldflags="-arch $DARWIN_ARCH -mmacosx-version-min=13.0" \
    --disable-shared --enable-static --disable-asm --disable-autodetect \
    --disable-gpl --disable-nonfree --disable-network --disable-doc \
    --disable-programs --enable-ffprobe --disable-everything \
    --enable-demuxer=mpegps --enable-parser=mpegvideo \
    --enable-decoder=mpeg2video --enable-protocol=file
  make -j4 ffprobe
  cp ffprobe "$ROOT_DIR/dist/ffprobe-$DARWIN_ARCH"
done

lipo -create "$ROOT_DIR/dist/ffprobe-arm64" "$ROOT_DIR/dist/ffprobe-x86_64" -output "$OUTPUT"
chmod +x "$OUTPUT"
"$OUTPUT" -L > "$ROOT_DIR/dist/FFmpeg-LICENSE.txt"
"$OUTPUT" -version > "$ROOT_DIR/dist/FFmpeg-BUILD.txt"
if ! "$OUTPUT" -demuxers 2>/dev/null | rg -q 'mpeg +MPEG-PS'; then
  echo "Built ffprobe lacks the MPEG-PS demuxer" >&2
  exit 1
fi
if [[ -n "${SAMPLE_MPG:-}" ]]; then
  "$OUTPUT" -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1 "$SAMPLE_MPG" >/dev/null
fi
cp "$ARCHIVE" "$ROOT_DIR/dist/ffmpeg-$VERSION-source.tar.xz"
if rg -q 'GNU General Public License' "$ROOT_DIR/dist/FFmpeg-LICENSE.txt"; then
  echo "Expected an LGPL-only ffprobe build, but found GPL terms" >&2
  exit 1
fi
echo "Built $OUTPUT"
