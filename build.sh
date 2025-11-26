#!/bin/bash
set -e

# Setup Flutter
export PATH="$PATH:$PWD/flutter/bin"
flutter config --no-analytics --no-cli-animations

# Navigate to flutter_app
if [ -d "flutter_app" ]; then
  cd flutter_app
elif [ -f "pubspec.yaml" ]; then
  echo "Already in Flutter project directory"
else
  echo "Error: Cannot find Flutter project"
  ls -la
  exit 1
fi

# Build
flutter pub get
flutter build web --release --verbose

echo "Build complete!"
ls -la build/web/
