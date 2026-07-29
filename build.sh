#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
echo "=== FLUTTER WEB BUILD SYSTEM ==="

export FLUTTER_ROOT="/usr/local/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"

if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "Cloning Flutter SDK stable..."
  git clone -b stable --depth 1 https://github.com/flutter/flutter.git $FLUTTER_ROOT
fi

# 4. Disable analytics & enable web
echo "Configuring Flutter..."
git config --global --add safe.directory $FLUTTER_ROOT
flutter config --no-analytics
flutter config --enable-web

# 5. Run pub get
echo "Running flutter pub get..."
flutter pub get

# 6. Build Web App
echo "Building Flutter web app..."
flutter build web --release --no-tree-shake-icons
echo "=== BUILD COMPLETE ==="
