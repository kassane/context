#!/bin/bash

# Array of git URLs
GIT_URLS=(
  "git+https://github.com/boostorg/assert"
  "git+https://github.com/boostorg/core"
  "git+https://github.com/boostorg/config"
  "git+https://github.com/boostorg/intrusive"
  "git+https://github.com/boostorg/predef"
  "git+https://github.com/boostorg/preprocessor"
  "git+https://github.com/boostorg/smart_ptr"
)

# Loop through each URL
for GIT_URL in "${GIT_URLS[@]}"
do
  # Extract the package name from the URL
  PKG_NAME=$(basename "$GIT_URL")

  # Use zig fetch with the package name and URL
  zig fetch --save="$PKG_NAME" "$GIT_URL"
done
