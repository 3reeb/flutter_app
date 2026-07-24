#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Installing Flutter..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter web app..."
flutter build web --release --web-renderer canvaskit --no-tree-shake-icons

echo "Build complete."
