#!/bin/bash

# 1. Install Flutter (Shallow clone for speed)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verify and Setup
flutter config --enable-web

# 3. Get Dependencies
echo "Fetching project dependencies..."
flutter pub get

# 4. Build for Web (CanvasKit for better performance)
echo "Building Flutter Web (Release mode)..."
flutter build web --release --web-renderer canvaskit

# 5. Build is located in build/web
echo "Build complete."
