#!/bin/bash
# Automatically setup KDE Plasma 6 keyboard shortcut for speak command
# Uses .desktop file and kglobalshortcutsrc (Plasma 6 method)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SHORTCUT_NAME="text-to-speak"
SHORTCUT_KEY="Alt+Esc"
COMMAND="wl-paste --primary | speak"
DESKTOP_ID="net.local.sh"

echo "Setting up KDE Plasma 6 keyboard shortcut for Kokoro TTS"
echo "=========================================================="
echo ""
echo "Shortcut: $SHORTCUT_KEY"
echo "Command: $COMMAND"
echo ""

# Check if we're in KDE Plasma 6
if [ -z "$KDE_SESSION_VERSION" ]; then
    echo -e "${YELLOW}Warning: Not running in KDE Plasma session${NC}"
    echo "This script is designed for KDE Plasma 6."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
elif [ "$KDE_SESSION_VERSION" != "6" ]; then
    echo -e "${YELLOW}Warning: This script is designed for Plasma 6, detected version $KDE_SESSION_VERSION${NC}"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Directories
CONFIG_FILE="$HOME/.config/kglobalshortcutsrc"
DESKTOP_DIR="/usr/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/${DESKTOP_ID}.desktop"

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
    echo "Backing up existing kglobalshortcutsrc..."
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

echo "Creating .desktop file..."

# Create the .desktop file in system location
# Check if we can write to /usr/share/applications (requires root or is already there from .deb)
if [ -w "$DESKTOP_DIR" ]; then
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Exec=$COMMAND
Name=$SHORTCUT_NAME
NoDisplay=true
StartupNotify=false
Type=Application
X-KDE-GlobalAccel-CommandShortcut=true
EOF
    echo "Desktop file created in system location: $DESKTOP_FILE"
elif [ -f "$DESKTOP_FILE" ]; then
    echo "Desktop file already exists at: $DESKTOP_FILE"
else
    echo "Note: .desktop file in /usr/share/applications not writable (this is OK if installed via .deb)"
fi

echo "Registering shortcut with kglobalaccel..."

# The component name for .desktop files in kglobalshortcutsrc
COMPONENT="services][${DESKTOP_ID}.desktop"

# Add the shortcut to kglobalshortcutsrc
# Format from working example: [services][net.local.sh.desktop]
# _launch=Alt+Esc
# Note: kwriteconfig6 escapes brackets, so we need to write directly to the file
if grep -q "^\[services\]\[${DESKTOP_ID}.desktop\]" "$CONFIG_FILE"; then
    echo "Shortcut entry already exists, updating..."
    kwriteconfig6 --file kglobalshortcutsrc --group "services][${DESKTOP_ID}.desktop" --key "_launch" "$SHORTCUT_KEY"
else
    echo "Adding new shortcut entry..."
    # Append the entry directly to avoid bracket escaping
    cat >> "$CONFIG_FILE" <<EOF

[services][${DESKTOP_ID}.desktop]
_launch=$SHORTCUT_KEY
EOF
fi

# Fix any escaped brackets that kwriteconfig6 might have created
sed -i 's/\[\\x5bservices\\x5d\\x5b\(.*\)\.desktop\]/[services][\1.desktop]/' "$CONFIG_FILE"

echo ""
echo "Reloading shortcuts..."

# Restart kglobalaccel to pick up the new configuration
echo "Restarting kglobalaccel service..."
kquitapp6 kglobalaccel 2>/dev/null || true
sleep 1
# kglobalaccel will auto-restart when needed

echo ""
echo -e "${GREEN}Shortcut created successfully!${NC}"
echo ""
echo "Desktop file: $DESKTOP_FILE"
echo "Config entry: [$COMPONENT"
echo ""
echo "Shortcut: $SHORTCUT_KEY"
echo "Action: $COMMAND"
echo ""
echo -e "${YELLOW}To test:${NC}"
echo "1. Select some text"
echo "2. Press $SHORTCUT_KEY"
echo "3. Listen to the selected text being spoken"
echo ""
echo "If the shortcut doesn't work immediately:"
echo "1. Try pressing $SHORTCUT_KEY again"
echo "2. Or log out and log back in"
echo ""
echo "To verify the shortcut:"
echo "1. Open System Settings > Keyboard > Shortcuts"
echo "2. Look for '$SHORTCUT_NAME' in the list"
