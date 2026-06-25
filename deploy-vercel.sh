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

# Ensure the flutter tool is executable
chmod +x ./flutter/bin/flutter

# 4. Build
echo "Fetching project dependencies..."
./flutter/bin/flutter pub get

echo "Building Flutter Web..."
# Changed renderer to 'auto' for better compatibility with your advanced theme
# Added --no-pub to use the 'get' we just did
./flutter/bin/flutter build web --release --base-href / --web-renderer auto --no-pub

echo "Build complete."
