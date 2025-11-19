# Maya-2026-Fedora-43-Install-Fix
Install fix for Autodesk Maya 2026 on Fedora 43.
Autodesk Maya 2026 Installer for Fedora 43

This repository contains Bash scripts to automate the installation of Autodesk Maya 2026 on Fedora 43 (and likely Fedora 40+ / Rawhide).

The official Autodesk Setup GUI installer often fails on Fedora with Error Code 1 or crashes due to dependency checks designed strictly for RHEL/Rocky Linux. These scripts bypass the GUI installer entirely, manually installing the RPM packages in the correct order, and patching the system libraries to make Maya run on bleeding-edge Linux distributions.

What these scripts do

    1_install_bypass.sh:

        Bypasses the Setup wrapper.

        Installs System Dependencies (including legacy libpng15).

        Installs RPMs using rpm --nodigest to bypass Fedora's strict SHA-1 signature rejection.

        Installs components in the correct dependency order (Identity Manager -> Flexnet -> AdlmApps -> Licensing -> Maya).

        Installs sub-components (Bifrost, MtoA, Substance, Flow, Retopology).

    2_post_install_fix.sh:

        Detects the specific installation directory (fixing case-sensitivity issues, e.g., maya2026 vs Maya2026).

        Symlinks Fedora's newer libtiff.so.6 (or .7) to the libtiff.so.5 required by Maya.

        Fixes directory permissions.

        Generates a working .desktop launcher so Maya appears in your App Grid/Dock.

Prerequisites

    Fedora 43 (or recent Fedora version).

    Root/Sudo privileges.

    The Maya 2026 installation media (downloaded from your Autodesk Account).

Installation Instructions

1. Prepare the Files

    Download and extract your Maya 2026 archive (usually a .tgz or .zip).

    Navigate into the extracted folder. You should see a folder named Packages (or you might be inside it depending on how you extracted it).

    Crucial Step: Download the two .sh scripts from this repository and place them inside the folder that contains the .rpm files (usually the Packages folder).

2. Run the Installer

Open your terminal in the Packages folder where you placed the scripts.

Make the scripts executable:
Bash

chmod +x 1_install_bypass.sh
chmod +x 2_post_install_fix.sh

Run the first script to install the software:
Bash

sudo ./1_install_bypass.sh

Note: You may see warnings about "NOKEY" or signatures. This is normal as we are forcing the install of older signatures on Fedora.

3. Run the Fixer

Once the installation is complete, run the second script to patch the libraries and create shortcuts:
Bash

sudo ./2_post_install_fix.sh

4. Register the License

Because we bypassed the official installer, the licensing service may not know which product you are trying to run.

If Maya does not launch or complains about a missing license:

    Open pkg.maya.xml (located in the same folder) and find your Product Key (e.g., 657R1).

    Run the following command (replace 657R1 with your specific key if different):

Bash

sudo /opt/Autodesk/AdskLicensing/Current/helper/AdskLicensingInstHelper register -pk 657R1 -pv 2026.0.0.F -cf /var/opt/Autodesk/Adlm/Maya2026/MayaConfig.pit -el EN

Troubleshooting

"Color Management" or Segfault on Launch

Fedora's locale settings can sometimes conflict with Maya's color management engine (SynColor). If Maya crashes immediately upon opening:

Run this in the terminal before launching Maya:
Bash

export LC_ALL=C
/usr/autodesk/maya2026/bin/maya

Wayland Issues

Maya is historically an X11 application. If you experience viewport flickering, black screens, or mouse lag:

    Log out of Fedora.

    Click the gear icon at the login screen.

    Select "GNOME on Xorg" (or standard X11).

Missing libpng15

The installer script attempts to install libpng15. If it fails (because Fedora 43 might have removed it from repos), you may need to manually download a libpng15 RPM from the Fedora 34 archives (rpmfind.net) and install it manually.

Disclaimer

These scripts are not affiliated with or endorsed by Autodesk. They are community-provided workarounds for installing software on unsupported Linux distributions. Use at your own risk.
