#!/usr/bin/env bash

set -x

AUFS_REPO="https://github.com/sfjro/aufs-standalone.git"

# Ensure we have the base env vars we expect
EXPECTED_VARS=(
    "KERNEL_FULL_VERSION"
    "KERNEL_TYPE" 
    "EL_VERSION"
    "RELEASE_VERSION"
)

for each in "${EXPECTED_VARS[@]}"; do
    if ! [[ -v $each ]]; then
        echo "ERROR: $each is unset. Exiting."
        exit 1
    fi
done

# Default to doing a full kernel build, unless we specify to only build the source RPM
if [[ ! -v SOURCE_RPM_ONLY ]]; then
    echo "$SOURCE_RPM_ONLY is unset, doing a full build..."
    SOURCE_RPM_ONLY=0
else
    if [[ $SOURCE_RPM_ONLY -eq 0 ]]; then
        echo "Full build requested..."
    elif [[ $SOURCE_RPM_ONLY -eq 1 ]]; then
        echo "Source RPM-only build requested..."
    fi
fi

# Set up our variables. From here, we'll know what kind of kernel we're setting up
IFS='-' read -r -a KERNEL_TYPE_ARRAY <<< $KERNEL_TYPE

if [[ ${#KERNEL_TYPE_ARRAY[@]} -ne "3" ]]; then
    echo "Kernel type $KERNEL_TYPE not recognized."
    exit 1
else
    # In case we put this in upper case for some reason.
    KERNEL_TYPE_SHORT=${KERNEL_TYPE_ARRAY[1],,}
fi

# Set our base kernel version from the full version
IFS='.' read -r -a VERSION_ARRAY <<< $KERNEL_FULL_VERSION
KERNEL_BASE_VERSION="${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}"

# Make sure we have the latest code
git clone https://github.com/bnied/$KERNEL_TYPE.git /opt/$KERNEL_TYPE

# Get our RPM dependencies
cd /opt/$KERNEL_TYPE/specs-$EL_VERSION/
yum-builddep -y $KERNEL_TYPE-$KERNEL_BASE_VERSION.spec

# Create our build directories
mkdir -p /root/rpmbuild/{SOURCES,SPECS,RPMS,SRPMS}

# Copy our build files to the appropriate directories
cd /opt/$KERNEL_TYPE/
cp configs-$EL_VERSION/config-$KERNEL_FULL_VERSION* /root/rpmbuild/SOURCES/
cp configs-$EL_VERSION/cpupower.* /root/rpmbuild/SOURCES/
cp specs-$EL_VERSION/$KERNEL_TYPE-$KERNEL_BASE_VERSION.spec /root/rpmbuild/SPECS/

# Copy additional files for EL8 kernels
if [[ "$EL_VERSION" == "el8" || "$EL_VERSION" == "el9" ]]; then
    cp configs-$EL_VERSION/mod-extra.list /root/rpmbuild/SOURCES/
    cp scripts-$EL_VERSION/* /root/rpmbuild/SOURCES/
fi

if [[ "$EL_VERSION" == "el9" ]]; then
    cp configs-$EL_VERSION/kvm_stat.logrotate /root/rpmbuild/SOURCES/
    cp configs-$EL_VERSION/rheldup3.x509 /root/rpmbuild/SOURCES/
    cp configs-$EL_VERSION/rhelkpatch1.x509 /root/rpmbuild/SOURCES/
    cp configs-$EL_VERSION/x509.genkey /root/rpmbuild/SOURCES/
fi

# Get our aufs-standalone source
cd /root/rpmbuild/SOURCES/
if [[ "$KERNEL_BASE_VERSION" == "5.10" ]]; then
    git clone $AUFS_REPO -b aufs5.10.82 aufs-standalone
elif [[ "$KERNEL_BASE_VERSION" == "5.15" ]]; then
    git clone $AUFS_REPO -b aufs5.15.41 aufs-standalone
elif [[ "$KERNEL_BASE_VERSION" == "5.17" ]]; then
    git clone $AUFS_REPO -b aufs5.17.3 aufs-standalone
else
    git clone $AUFS_REPO -b aufs$KERNEL_BASE_VERSION aufs-standalone
fi

# If there's no branch matching our kernel version, use aufs5.x-rcN
if [[ $? != 0 ]]; then
    git clone $AUFS_REPO -b aufs${VERSION_ARRAY[0]}.x-rcN aufs-standalone
fi

# Tar up our aufs source and remove the git directory
cd /root/rpmbuild/SOURCES/aufs-standalone
HEAD_COMMIT=$(git rev-parse --short HEAD)
git archive $HEAD_COMMIT > ../aufs-standalone.tar
rm -rf /root/rpmbuild/SOURCES/aufs-standalone

# Build our source RPM with spectool and rpmbuild
cd /root/rpmbuild/SPECS/
spectool -g -C /root/rpmbuild/SOURCES/ $KERNEL_TYPE-$KERNEL_BASE_VERSION.spec
rpmbuild -bs $KERNEL_TYPE-$KERNEL_BASE_VERSION.spec

# Rebuild our source RPM into actual RPMs
if [[ $SOURCE_RPM_ONLY -eq 0 ]]; then
    cd /root/rpmbuild/SRPMS/
    rpmbuild --rebuild $KERNEL_TYPE-$KERNEL_FULL_VERSION-$RELEASE_VERSION.$EL_VERSION.src.rpm
fi

# Copy our finished RPMs to our storage directory
mkdir -p /root/$KERNEL_TYPE_SHORT/SRPMS
cp -av /root/rpmbuild/SRPMS/* /root/$KERNEL_TYPE_SHORT/SRPMS/
cp -av /root/rpmbuild/RPMS/* /root/$KERNEL_TYPE_SHORT/

# Delete our build directories, to save space
rm -rf /root/rpmbuild/*
