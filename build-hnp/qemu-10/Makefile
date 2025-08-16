include ../utils/Makefrag

# to disable jit, add --enable-tcg-interpreter option

all: download/qemu
	rm -rf temp build
	mkdir -p temp build/bin
	cd download/qemu && git worktree add -f $(shell pwd)/temp/qemu HEAD
	cd temp/qemu && \
	PKG_CONFIG=$(shell which pkg-config) \
	PKG_CONFIG_PATH= \
	PKG_CONFIG_LIBDIR=$(shell pwd)/../buildroot/lib/pkgconfig:$(shell pwd)/../buildroot/share/pkgconfig \
	PKG_CONFIG_SYSROOT_DIR=$(shell pwd)/../buildroot \
	CFLAGS="-D_UAPI_LINUX_VIRTIO_VSOCK_H -D_UAPI_LINUX_VIRTIO_TYPES_H -D_UAPI_LINUX_VIRTIO_RING_H -D_UAPI_LINUX_VIRTIO_PMEM_H -D_UAPI_LINUX_VIRTIO_NET_H -D_UAPI_LINUX_VIRTIO_IOMMU_H -D_UAPI_LINUX_VIRTIO_FS_H -D_UAPI_LINUX_VIRTIO_CONSOLE_H -D_UAPI_LINUX_VIRTIO_CONFIG_H -D_LINUX_SYSINFO_H -UHAVE_OPENAT2_H -UTARGET_NR_mq_open -D__user= -D__force= ${CFLAGS}" \
	./configure --target-list=aarch64-linux-user,x86_64-linux-user --cross-prefix= --host-cc=cc --disable-kvm --disable-xen --disable-rust --disable-docs --disable-system --disable-werror --static \
	 --disable-bsd-user --disable-guest-agent --disable-gcrypt --disable-debug-info --disable-debug-tcg --enable-attr --disable-brlapi --disable-linux-aio --disable-bzip2 --disable-cap-ng --disable-curl --disable-fdt --disable-glusterfs --disable-gnutls --disable-nettle --disable-gtk --disable-rdma --disable-libiscsi --disable-vnc-jpeg --disable-kvm --disable-lzo --disable-curses --disable-libnfs --disable-numa --disable-opengl --disable-rbd --disable-vnc-sasl --disable-sdl --disable-seccomp --disable-smartcard --disable-snappy --disable-spice --disable-libusb --disable-usb-redir --disable-vde --disable-vhost-net --disable-virglrenderer --disable-virtfs --disable-vnc --disable-vte --disable-xen --disable-xen-pci-passthrough --enable-linux-user --disable-tools
	cd temp/qemu && make -j $(shell nproc) && make install DESTDIR=$(shell pwd)/build
	$(OHOS_SDK_HOME)/native/llvm/bin/llvm-strip ./build/usr/local/bin/*
	mkdir -p ../sysroot/bin
	cp -rv ./build/usr/local/bin/qemu-aarch64 ../sysroot/bin/qemu-harmonix-aarch64
	cp -rv ./build/usr/local/bin/qemu-x86_64 ../sysroot/bin/qemu-harmonix-x86_64
	cp -rv ./scripts/* ../sysroot/bin/

download/qemu:
	mkdir -p download
	cd download && git clone -b termony-qemu-10-vroot --depth=100 https://github.com/hackeris/harmony-qemu qemu
