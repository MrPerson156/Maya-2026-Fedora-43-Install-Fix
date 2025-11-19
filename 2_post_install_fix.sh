#!/bin/bash

# Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root (sudo ./finish_maya_lowercase.sh)"
    exit 1
fi

# Define the confirmed lowercase path
MAYA_ROOT="/usr/autodesk/maya2026"

echo "--- Finalizing Maya 2026 Setup (Lowercase Fix) ---"

# 0. VERIFY PATH EXISTS
if [ ! -d "$MAYA_ROOT" ]; then
    echo "CRITICAL ERROR: Directory $MAYA_ROOT does not exist."
    echo "Please verify your installation folder name in /usr/autodesk/"
    exit 1
fi

# 1. FIX LIBTIFF (Link System .6 to Maya .5)
echo ">>> Fixing libtiff.so.5 dependency..."
SYS_LIBTIFF="/usr/lib64/libtiff.so.6"

if [ -f "$SYS_LIBTIFF" ]; then
    ln -sf "$SYS_LIBTIFF" "$MAYA_ROOT/lib/libtiff.so.5"
    echo "SUCCESS: Linked system libtiff.so.6 to $MAYA_ROOT/lib/libtiff.so.5"
else
    echo "WARNING: /usr/lib64/libtiff.so.6 not found. Checking for .7..."
    # Fallback for future Fedora versions
    if [ -f "/usr/lib64/libtiff.so.7" ]; then
         ln -sf "/usr/lib64/libtiff.so.7" "$MAYA_ROOT/lib/libtiff.so.5"
         echo "SUCCESS: Linked system libtiff.so.7 to $MAYA_ROOT/lib/libtiff.so.5"
    else
         echo "ERROR: No libtiff found in /usr/lib64. You may need to install it."
    fi
fi

# 2. FIX PERMISSIONS
echo ">>> Fixing directory permissions..."
chmod -R 755 "$MAYA_ROOT"
echo "Permissions set to 755 for $MAYA_ROOT"

# 3. CREATE DESKTOP SHORTCUT
echo ">>> Creating Desktop Launcher..."
DESKTOP_FILE="/usr/share/applications/autodesk-maya-2026.desktop"

# Auto-detect icon name (Maya.png vs maya.png)
if [ -f "$MAYA_ROOT/icons/Maya.png" ]; then
    ICON_PATH="$MAYA_ROOT/icons/Maya.png"
else
    # Find any png in that folder if the specific name fails
    ICON_PATH=$(find "$MAYA_ROOT/icons" -name "*.png" | head -n 1)
fi

cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=Autodesk Maya 2026
Comment=Autodesk Maya 2026
Exec=$MAYA_ROOT/bin/maya
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;
Keywords=3d;cg;modeling;animation;rendering;
StartupNotify=true
EOL

chmod +x "$DESKTOP_FILE"
echo "SUCCESS: Launcher created at $DESKTOP_FILE"

echo "-------------------------------------------------------"
echo "FINISHED. You can now launch Maya 2026."
echo "-------------------------------------------------------"
