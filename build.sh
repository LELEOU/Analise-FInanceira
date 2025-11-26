#!/bin/bash

echo "=== Starting Flutter Build ==="
echo "Working directory: $PWD"
echo "Contents:"
ls -la

echo ""
echo "=== Setting up Flutter ==="
export PATH="$PATH:$PWD/flutter/bin"
which flutter || echo "Flutter not in PATH!"

echo ""
echo "=== Flutter Config ==="
flutter config --no-analytics --no-cli-animations 2>&1 || true

echo ""
echo "=== Navigating to project ==="
if [ -d "flutter_app" ]; then
  echo "Found flutter_app directory, entering..."
  cd flutter_app
  pwd
  ls -la
elif [ -f "pubspec.yaml" ]; then
  echo "Already in Flutter project directory"
else
  echo "ERROR: Cannot find Flutter project!"
  exit 1
fi

echo ""
echo "=== Installing dependencies ==="
flutter pub get || { echo "pub get failed"; exit 1; }

echo ""
echo "=== Building for web ==="
flutter build web --release || { echo "Build failed"; exit 1; }

echo ""
echo "=== Build complete! ==="
ls -la build/web/ || echo "build/web not found"
