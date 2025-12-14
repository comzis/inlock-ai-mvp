#!/bin/bash
# Convert PNG to ICO using ImageMagick or create a simple ICO
# If ImageMagick available, use it; otherwise create symlink
if command -v convert &> /dev/null; then
  convert app/favicon.png -resize 32x32 app/favicon.ico
  echo "Created app/favicon.ico using ImageMagick"
elif command -v magick &> /dev/null; then
  magick app/favicon.png -resize 32x32 app/favicon.ico
  echo "Created app/favicon.ico using ImageMagick (magick)"
else
  # Fallback: Copy PNG as ICO (most browsers accept PNG as ICO)
  cp app/favicon.png app/favicon.ico
  echo "Created app/favicon.ico by copying PNG (browsers will accept PNG format)"
fi
