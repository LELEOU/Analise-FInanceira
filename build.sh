#!/bin/bash
set -e

echo "📦 Setting up Flutter..."
export PATH="$PATH:$PWD/flutter/bin"

echo "🔧 Configuring Flutter..."
flutter config --no-analytics

echo "📂 Current directory: $PWD"
ls -la

echo "🏗️ Building Flutter Web..."
cd flutter_app
echo "📂 Now in: $PWD"
ls -la

flutter pub get
flutter build web --release

echo "✅ Build complete!"
