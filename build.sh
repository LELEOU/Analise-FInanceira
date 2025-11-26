#!/bin/bash
set -e

echo "📦 Setting up Flutter..."
export PATH="$PATH:$PWD/flutter/bin"

echo "🔧 Configuring Flutter..."
flutter config --no-analytics
flutter doctor

echo "🏗️ Building Flutter Web..."
cd flutter_app
flutter pub get
flutter build web --release

echo "✅ Build complete!"
