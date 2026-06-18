#!/bin/bash

# 1. Exit on error
set -e

# 2. Install Flutter (Shallow clone for speed)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 3. Setup Environment
export PATH="$PATH:$(pwd)/flutter/bin"
# Set HOME to current dir to avoid permission issues
export HOME=$(pwd)

# 4. Build
echo "Fetching project dependencies..."
./flutter/bin/flutter pub get

echo "Building Flutter Web (Release mode)..."
# Removed --web-renderer to avoid parsing errors from CRLF line endings
./flutter/bin/flutter build web --release

echo "Build complete."
