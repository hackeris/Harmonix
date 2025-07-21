include ../utils/Makefrag

all: download/qemu
	rm -rf temp build
	mkdir -p temp build/bin
	cd temp && cp -vr ../download/qemu qemu
	cd temp/qemu && \
	PKG_CONFIG=$(shell which pkg-config) \
	PKG_CONFIG_PATH= \
	PKG_CONFIG_LIBDIR=$(shell pwd)/../buildroot/lib/pkgconfig:$(shell pwd)/../buildroot/share/pkgconfig \
	PKG_CONFIG_SYSROOT_DIR=$(shell pwd)/../buildroot \
	CFLAGS="-D_UAPI_LINUX_VIRTIO_VSOCK_H -D_UAPI_LINUX_VIRTIO_TYPES_H -D_UAPI_LINUX_VIRTIO_RING_H -D_UAPI_LINUX_VIRTIO_PMEM_H -D_UAPI_LINUX_VIRTIO_NET_H -D_UAPI_LINUX_VIRTIO_IOMMU_H -D_UAPI_LINUX_VIRTIO_FS_H -D_UAPI_LINUX_VIRTIO_CONSOLE_H -D_UAPI_LINUX_VIRTIO_CONFIG_H -D_LINUX_SYSINFO_H -D__user= -D__force= ${CFLAGS} -I$(shell pwd)/../buildroot/include/glib-2.0 -I$(shell pwd)/../buildroot/lib/glib-2.0/include -L$(shell pwd)/../buildroot/lib" \
	./configure --target-list=aarch64-linux-user,x86_64-linux-user --cross-prefix= --host-cc=cc --disable-kvm --disable-xen --disable-docs --disable-system --enable-tcg-interpreter --disable-werror --static \
	 --disable-bsd-user --disable-guest-agent --disable-strip --disable-gcrypt --disable-debug-info --disable-debug-tcg --enable-attr --disable-brlapi --disable-linux-aio --disable-bzip2 --disable-cap-ng --disable-curl --disable-fdt --disable-glusterfs --disable-gnutls --disable-nettle --disable-gtk --disable-rdma --disable-libiscsi --disable-vnc-jpeg --disable-kvm --disable-lzo --disable-curses --disable-libnfs --disable-numa --disable-opengl --disable-vnc-png --disable-rbd --disable-vnc-sasl --disable-sdl --disable-seccomp --disable-smartcard --disable-snappy --disable-spice --disable-libusb --disable-usb-redir --disable-vde --disable-vhost-net --disable-virglrenderer --disable-virtfs --disable-vnc --disable-vte --disable-xen --disable-xen-pci-passthrough --disable-xfsctl --enable-linux-user --disable-blobs --disable-tools
	cd temp/qemu && make -j $(shell nproc)
	cp temp/qemu/aarch64-linux-user/qemu-aarch64 ./build/bin/
	cp temp/qemu/x86_64-linux-user/qemu-x86_64 ./build/bin/
	$(OHOS_SDK_HOME)/native/llvm/bin/llvm-strip ./build/bin/*
	mkdir -p ../sysroot/bin
	cp -rv ./build/bin/qemu-aarch64 ../sysroot/bin/qemu-harmonix-aarch64
	cp -rv ./build/bin/qemu-x86_64 ../sysroot/bin/qemu-harmonix-x86_64
	cp -rv ./scripts/* ../sysroot/bin/

download/qemu:
	mkdir -p download
	cd download && git clone -b termony-qemu-vroot --depth=1 https://github.com/hackeris/harmony-qemu qemu