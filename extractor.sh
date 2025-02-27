#!/bin/bash
# repack_debs.sh
# This script downloads a package and its dependencies, extracts them using dpkg-deb,
# and then repacks the extracted files into a tarball for deployment on your Yocto device.
# It also demonstrates how to exclude core/system files (like libc and related libraries)
# to avoid overwriting device-specific components.

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

PACKAGE="$1"
WORKDIR="$(pwd)/deb_packages"
FINALDIR="$(pwd)/final_rootfs"
TARFILE="yocto_rootfs.tar.gz"

# Create working directories
mkdir -p "$WORKDIR" "$FINALDIR"

echo "Updating package lists..."
sudo apt update

echo "Downloading package '$PACKAGE' and its dependencies..."
# Get dependencies recursively (adjust options as needed)
#DEBS=$(apt-cache depends --recurse --no-recommends "$PACKAGE" | grep "^[a-zA-Z0-9]" | sort -u)
#echo $DEBS
#echo "NOW"
DEBS=$(apt-cache depends "$PACKAGE" | awk '/Depends:/ {print $2}')
echo $DEBS
# Include the main package
DEBS="$PACKAGE $DEBS"
echo "Packages to download: $DEBS"
cd "$WORKDIR"
apt-get download $DEBS

echo "Extracting .deb files using dpkg-deb into $FINALDIR..."
for deb in *.deb; do
    echo "Processing $deb..."
    dpkg-deb -x "$deb" "$FINALDIR"
done

# At this point, $FINALDIR contains the file tree (e.g. /etc, /usr, /lib, etc.)
# that came from the packages.

# Exclude core system files to avoid breaking your device.
# Adjust the --exclude patterns as needed.
EXCLUDES=(
    --exclude="usr/lib/libc.so*"
    --exclude="lib/libc.so*"
    --exclude="usr/lib/linux-libc-dev/*"
    --exclude="usr/share/doc/dpkg*"
    --exclude="etc/ld.so.cache"
)

echo "Creating tarball ($TARFILE) from the extracted files (excluding core libraries)..."
tar czvf "$TARFILE" -C "$FINALDIR" "${EXCLUDES[@]}" .

echo "Done!"
echo "Transfer $TARFILE to your Yocto device and extract it at root:"
echo "scp $TARFILE root@<yocto-device>:/tmp/"
echo "On the Yocto device, run:"
echo "tar xzvf /tmp/$TARFILE -C /"
