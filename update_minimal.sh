#!/bin/bash

echo "Updating macOS and App Store apps..."
softwareupdate --all --install --force

if command -v mas &>/dev/null; then
    mas upgrade
else
    echo "mas is not installed. Install it with 'brew install mas' to update App Store apps."
fi

echo "Updating Homebrew and packages..."
brew update
brew upgrade
brew cleanup

echo "Updates complete!"
