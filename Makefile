build_7:
	docker build --rm=true -t bnied/kernel-aufs-build-image:el7 -f el7/Dockerfile .

build_8:
	docker build --rm=true -t bnied/kernel-aufs-build-image:el8 -f el8/Dockerfile .

release_7:
	docker push bnied/kernel-aufs-build-image:el7

release_8:
	docker push bnied/kernel-aufs-build-image:el8

build_all:
	make build_7
	make build_8

release_all:
	make release_7
	make release_8
	