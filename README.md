# kernel-aufs-build-image

A Docker image to build the `kernel-{lt|ml|rc}-aufs` kernels.

## Usage:
```sh
docker run \
	-v {directory for /root}:/root \
	-v {directory for rpmbuild}:/root/rpmbuild \
	--env KERNEL_FULL_VERSION={kernel version} \
	--env RELEASE_VERSION={release version} \
	--env KERNEL_TYPE={kernel type} \
	--env EL_VERSION={el version} \
	{tag for build image}
```

Ex:
```sh
docker run \
	-v /home/user/RPMs:/root \
	-v /home/user/rpmbuild/lt/el7:/root/rpmbuild \
	--env KERNEL_FULL_VERSION=5.10.61 \
	--env RELEASE_VERSION=1 \
	--env KERNEL_TYPE=kernel-lt-aufs \
	--env EL_VERSION=el7 \
	docker.io/bnied/kernel-aufs-build-image:el7
```

## To build:
* `make build_7:`: Build EL7 image.
* `make build_8`: Build EL8 image.
* `make release_7`: Upload EL7 image.
* `make release_8`: Upload EL8 image.
* `make build_all`: Build all images.
* `make release_all`: Upload all images
