#!/bin/bash
# Install Gum for beautiful terminal menus

echo "Installing Gum - Beautiful Terminal Menus..."

# Install Gum
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install -y gum

# Verify installation
if command -v gum &> /dev/null; then
    echo "✅ Gum installed successfully!"
    echo "Your build selector will now have beautiful menus!"
    gum style --border rounded --padding "1 2" --border-foreground 2 "Gum is ready! 🎉"
else
    echo "❌ Gum installation failed"
fi