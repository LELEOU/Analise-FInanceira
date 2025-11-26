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
  echo "Current directory after cd: $(pwd)"
  echo "Contents of flutter_app:"
  ls -la
  
  if [ ! -d "lib" ]; then
    echo "ERROR: lib/ directory not found!"
    exit 1
  fi
  
  if [ ! -f "lib/main.dart" ]; then
    echo "ERROR: lib/main.dart not found!"
    echo "Contents of lib/:"
    ls -la lib/ 2>&1 || echo "lib/ doesn't exist"
    exit 1
  fi
  
  echo "lib/main.dart exists, proceeding..."
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
