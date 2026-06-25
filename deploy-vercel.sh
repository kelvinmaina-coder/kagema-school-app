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
export HOME=$(pwd)

# 4. Build
echo "Fetching project dependencies..."
./flutter/bin/flutter pub get

echo "Building Flutter Web..."
# Added --base-href / and explicitly set the renderer to html for compatibility
./flutter/bin/flutter build web --release --base-href / --web-renderer html

echo "Build complete."
