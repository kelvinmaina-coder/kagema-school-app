#!/bin/bash

# Exit on error
set -e

# 1. Install Flutter (Shallow clone for speed)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Set path and suppress root warning
export PATH="$PATH:$(pwd)/flutter/bin"
export HOME=$(pwd)

# 2. Verify and Setup
./flutter/bin/flutter config --enable-web

# 3. Get Dependencies
echo "Fetching project dependencies..."
./flutter/bin/flutter pub get

# 4. Build for Web
# Note: Using --web-renderer canvaskit is optional but recommended for performance.
# We use the absolute path to ensure we use the downloaded version.
echo "Building Flutter Web (Release mode)..."
./flutter/bin/flutter build web --release --web-renderer canvaskit

# 5. Build is located in build/web
echo "Build complete."
