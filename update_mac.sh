#!/bin/bash

# Function to display a section header
section() {
    echo "============================="
    echo "$1"
    echo "============================="
}

# Update macOS software
section "Updating macOS Software"
sudo softwareupdate -i -a

# Update App Store applications
section "Updating App Store Applications"
if command -v mas &>/dev/null; then
    mas upgrade
else
    echo "MAS (Mac App Store CLI) is not installed. Skipping App Store updates."
    echo "To install MAS, use: brew install mas"
fi

# Update Homebrew and installed packages
section "Updating Homebrew and Installed Packages"
brew update
brew upgrade
brew cleanup
brew autoremove

echo "============================="
echo "Update Process Complete"
echo "============================="
