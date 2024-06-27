#!/bin/bash

# Variables
REPO_PATH="/ubuntu-local"   # Path to your repository
DIST_NAME="focal"                      # Distribution name
GPG_KEY_ID="pkg-wfr3"               # Your GPG key ID
LABEL="ubuntu-local"

# Ensure necessary tools are installed
echo "Checking for required tools..."
if ! command -v apt-ftparchive &> /dev/null; then
    echo "apt-ftparchive could not be found, installing..."
    sudo apt-get install apt-utils -y
fi

if ! command -v gpg &> /dev/null; then
    echo "gpg could not be found, installing..."
    sudo apt-get install gnupg -y
fi

# Verify the GPG key is available
echo "Verifying GPG key..."
if ! gpg --list-keys | grep -q "$GPG_KEY_ID"; then
    echo "GPG key ID $GPG_KEY_ID not found in keyring."
    exit 1
fi

# Create a configuration file for apt-ftparchive
echo "Creating apt-ftparchive configuration..."
cat <<EOF > apt-ftparchive.conf
APT::FTPArchive::Release {
    Origin "Acubed Wayfinder";
    Label "$LABEL";
    Suite "$DIST_NAME";
    Codename "$DIST_NAME";
    Architectures "amd64 i386";
    Components "main";
    Description "$LABEL";
};
EOF

# Generate the Release file
echo "Generating Release file..."
apt-ftparchive -c=apt-ftparchive.conf release "$REPO_PATH/dists/$DIST_NAME" > "$REPO_PATH/dists/$DIST_NAME/Release"

# Sign the Release file
echo "Signing Release file..."
gpg --default-key "$GPG_KEY_ID" -abs -o "$REPO_PATH/dists/$DIST_NAME/Release.gpg" "$REPO_PATH/dists/$DIST_NAME/Release"
gpg --default-key "$GPG_KEY_ID" --clearsign -o "$REPO_PATH/dists/$DIST_NAME/InRelease" "$REPO_PATH/dists/$DIST_NAME/Release"

# Clean up
echo "Cleaning up..."
rm apt-ftparchive.conf

# Provide paths to the generated files
echo "Done. Your repository has been signed."
echo "Generated files:"
echo "$REPO_PATH/dists/$DIST_NAME/Release"
echo "$REPO_PATH/dists/$DIST_NAME/Release.gpg"
echo "$REPO_PATH/dists/$DIST_NAME/InRelease"
