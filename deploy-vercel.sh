#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$PWD/flutter/bin"

echo "Building Flutter web app..."
flutter pub get
flutter build web --release --no-tree-shake-icons

if [ -d "build/web" ]; then
    echo "✅ Build successful!"
    ls -la build/web/
else
    echo "❌ Build failed!"
    exit 1
fi