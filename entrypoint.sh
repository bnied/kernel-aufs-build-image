#!/usr/bin/env bash

set -x

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
git clone git://github.com/bnied/$KERNEL_TYPE.git /opt/$KERNEL_TYPE

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
if [[ "$EL_VERSION" == "el8" ]]; then
    cp configs-$EL_VERSION/mod-extra.list /root/rpmbuild/SOURCES/
    cp scripts-$EL_VERSION/* /root/rpmbuild/SOURCES/
fi

# Get our aufs-standalone source
cd /root/rpmbuild/SOURCES/

# aufs5.15 has no patch files. We need those.
if [[ $KERNEL_BASE_VERSION == '5.15' ]]; then
    git clone git://github.com/sfjro/aufs5-standalone.git -b aufs5.x-rcN aufs-standalone
else
    git clone git://github.com/sfjro/aufs5-standalone.git -b aufs$KERNEL_BASE_VERSION aufs-standalone
fi

# If there's no branch matching our kernel version, use aufs5.x-rcN
if [[ $? != 0 ]]; then
    git clone git://github.com/sfjro/aufs5-standalone.git -b aufs5.x-rcN aufs-standalone
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
cd /root/rpmbuild/SRPMS/
rpmbuild --rebuild $KERNEL_TYPE-$KERNEL_FULL_VERSION-$RELEASE_VERSION.$EL_VERSION.src.rpm

# Copy our finished RPMs to our storage directory
mkdir -p /root/$KERNEL_TYPE_SHORT/SRPMS
cp -av /root/rpmbuild/SRPMS/* /root/$KERNEL_TYPE_SHORT/SRPMS/
cp -av /root/rpmbuild/RPMS/* /root/$KERNEL_TYPE_SHORT/

# Delete our build directories, to save space
rm -rf /root/rpmbuild/*
