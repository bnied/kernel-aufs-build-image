build_7:
	@read -p "Enter your Docker username: " username; \
	docker build --rm=true -t $$username/kernel-aufs-build-image:el7 -f el7/Dockerfile .

build_8:
	@read -p "Enter your Docker username: " username; \
	docker build --rm=true -t $$username/kernel-aufs-build-image:el8 -f el8/Dockerfile .

build_9:
	@read -p "Enter your Docker username: " username; \
	docker build --rm=true -t $$username/kernel-aufs-build-image:el9 -f el9/Dockerfile .

release_7:
	@read -p "Enter your Docker username: " username; \
	docker push $$username/kernel-aufs-build-image:el7

release_8:
	@read -p "Enter your Docker username: " username; \
	docker push $$username/kernel-aufs-build-image:el8

release_9:
	@read -p "Enter your Docker username: " username; \
	docker push $$username/kernel-aufs-build-image:el9

build_all:
	make build_7
	make build_8
	make build_9

release_all:
	make release_7
	make release_8
	make release_9
