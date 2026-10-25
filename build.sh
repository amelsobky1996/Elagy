#!/usr/bin/env bash
# Builds the Flutter web app on Vercel (installs Flutter on the fly).
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true
flutter pub get
flutter build web --release --no-tree-shake-icons
