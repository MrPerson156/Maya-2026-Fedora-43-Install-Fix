#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root (sudo ./install_maya_repair.sh)"
    exit 1
fi

# Function to safely force install RPMs
safe_install() {
    local pkg_path="$1"
    local pkg_name="$2"
    local extra_flags="$3" # Optional flags like --nodeps

    if ls $pkg_path 1> /dev/null 2>&1; then
        echo ">>> Installing $pkg_name..."
        rpm -ivh --nodigest --nofiledigest --force $extra_flags $pkg_path
    else
        echo "WARNING: Could not find RPM for $pkg_name at $pkg_path"
    fi
}

echo "--- Starting Maya 2026 Repair Installation ---"

# 1. FIX SYSTEM ENVIRONMENT (The Python Error)
# Fedora uses /usr/bin/python3, but Maya plugins expect RHEL's /usr/libexec/platform-python
echo ">>> [1/8] Creating System Compatibility Links..."
if [ ! -f /usr/libexec/platform-python ]; then
    echo "Linking platform-python to python3..."
    ln -s /usr/bin/python3 /usr/libexec/platform-python
fi

# 2. INSTALL FLEXNET CLIENT (The AdlmApps Error)
# This was the missing dependency causing the licensing apps to fail
echo ">>> [2/8] Installing Flexnet Client..."
safe_install "./adskflexnetclient*.rpm" "Flexnet Client"

# 3. INSTALL IDENTITY & LICENSING (In Correct Order)
echo ">>> [3/8] Re-installing Licensing Infrastructure..."
safe_install "./AdskIdentityManager/*.rpm" "Identity Manager (v1.14)"
safe_install "./adlmapps*.rpm" "AdlmApps"
safe_install "./adsklicensing*.rpm" "Licensing Service"

# 4. INSTALL ADP SDK (The LookdevX Error)
# LookdevX failed because it needs this SDK, which is in the AdpSdk folder
echo ">>> [4/8] Installing Autodesk ADP SDK..."
if [ -d "./AdpSdk" ]; then
    safe_install "./AdpSdk/*.rpm" "AdpSdk"
else
    echo "WARNING: AdpSdk folder not found. LookdevX might fail again."
fi

# 5. RE-INSTALL MAYA CORE
echo ">>> [5/8] Verifying Maya Core..."
safe_install "./Maya2026*.rpm" "Maya 2026 Core"

# 6. INSTALL PLUGINS (With --nodeps to fix 'Shared Object' errors)
# We use --nodeps because we know Maya is installed, but sometimes RPM doesn't see the libraries immediately.
echo ">>> [6/8] Installing Plugins..."
safe_install "./Bifrost*.rpm" "Bifrost"
safe_install "./MayaUSD*.rpm" "MayaUSD"
safe_install "./AdobeSubstance*.rpm" "Substance"
safe_install "./LookdevX*.rpm" "LookdevX" "--nodeps"
safe_install "./MtoA*.rpm" "Arnold"

# 7. ATTEMPT FLOW INSTALL (Handling Corruption)
echo ">>> [7/8] Installing Flow Components..."
safe_install "./FlowService/*.rpm" "Flow Service"
safe_install "./FlowMaya/*.rpm" "Flow Maya Plugin" "--nodeps"
safe_install "./flowretopology/*.rpm" "Retopology"

# 8. FIX DESKTOP SHORTCUTS (The Dock Issue)
echo ">>> [8/8] Creating Desktop Shortcuts..."
# Maya installs the desktop file to a hidden internal folder. We copy it to the system.
MAYA_DESKTOP="/usr/autodesk/Maya2026/desktop/Maya2026.desktop"
SYSTEM_APPS="/usr/share/applications/"

if [ -f "$MAYA_DESKTOP" ]; then
    echo "Copying Maya launcher to system applications..."
    cp "$MAYA_DESKTOP" "$SYSTEM_APPS"
    
    # Fix the Icon path if it's broken in the desktop file (common bug)
    # We ensure the Icon line points to the actual png
    sed -i 's|^Icon=.*|Icon=/usr/autodesk/Maya2026/icons/Maya.png|g' "$SYSTEM_APPS/Maya2026.desktop"
    
    # Make it executable just in case
    chmod +x "$SYSTEM_APPS/Maya2026.desktop"
    
    # Refresh Gnome
    update-desktop-database "$SYSTEM_APPS"
    echo "SUCCESS: Maya 2026 should now appear in your Activities/Dock."
else
    echo "WARNING: Could not find $MAYA_DESKTOP. You may need to launch Maya via command line."
fi

echo "-------------------------------------------------------"
echo "REPAIR COMPLETE."
echo "1. If 'Flow Service' failed again with 'cpio: read failed', that specific RPM file is corrupted. You must re-download it."
echo "2. To launch Maya, search 'Maya 2026' in your dashboard or run: /usr/autodesk/Maya2026/bin/maya"
echo "-------------------------------------------------------"
