#!/bin/bash
# Generate all favicons and media assets for the site and AVO

cd "$(dirname "$0")/../"

echo "Generating favicons and media assets..."

# Create logo files from the existing icon.png
# Create favicon.ico (32x32)
echo "Creating favicon.ico..."
magick convert public/icon.png -background white -gravity center -extent 32x32 public/favicon.ico

# Create AVO-specific favicon (dark mode)
echo "Creating favicon-dark.ico..."
magick convert public/icon-dark.png -background black -gravity center -extent 32x32 public/favicon-dark.ico

# Create apple-touch-icon (180x180)
echo "Creating apple-touch-icon.png..."
magick convert public/icon.png -resize 180x180 public/apple-touch-icon.png

# Create favicon-32x32, favicon-16x16 for PWA
echo "Creating favicon-32x32.png..."
magick convert public/icon.png -resize 32x32 public/favicon-32x32.png

echo "Creating favicon-16x16.png..."
magick convert public/icon.png -resize 16x16 public/favicon-16x16.png

# Create android/chrome icons
echo "Creating android-chrome-192x192.png..."
magick convert public/icon.png -resize 192x192 public/android-chrome-192x192.png

echo "Creating android-chrome-512x512.png..."
magick convert public/icon.png -resize 512x512 public/android-chrome-512x512.png

# Update the icon.svg with content from icon.png (if it's empty)
if [ ! -s public/icon.svg ]; then
  echo "Updating icon.svg..."
  echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">' > public/icon.svg
  echo '  <image href="/icon.png" width="512" height="512"/>' >> public/icon.svg
  echo '</svg>' >> public/icon.svg
fi

# Update the icon-dark.svg with content from icon-dark.png (if it's empty)
if [ ! -s public/icon-dark.svg ]; then
  echo "Updating icon-dark.svg..."
  echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">' > public/icon-dark.svg
  echo '  <image href="/icon-dark.png" width="512" height="512"/>' >> public/icon-dark.svg
  echo '</svg>' >> public/icon-dark.svg
fi

# Update the placeholder.svg if it's empty
if [ ! -s public/placeholder.svg ]; then
  echo "Updating placeholder.svg..."
  echo '<?xml version="1.0" encoding="UTF-8"?>' > public/placeholder.svg
  echo '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">' >> public/placeholder.svg
  echo '  <rect width="200" height="200" fill="#0B8AE2"/>' >> public/placeholder.svg
  echo '  <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="60" fill="white" text-anchor="middle" dy=".3em">AVO</text>' >> public/placeholder.svg
  echo '</svg>' >> public/placeholder.svg
fi

echo "All favicons and media assets generated successfully!"