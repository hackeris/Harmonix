include ../utils/Makefrag

all: download/openssl-3.5.0.tar.gz
	rm -rf temp build
	mkdir -p temp build/bin
	cd temp && tar xvf ../download/openssl-3.5.0.tar.gz
	cd temp/openssl-3.5.0 && cat ../../0001-ohos-getauxval.diff | patch -Np1
	cd temp/openssl-3.5.0 && ./Configure linux-$(OHOS_ARCH) shared no-tests --prefix=$(PREFIX) --openssldir=$(PREFIX) --libdir=lib -D__OHOS__ CC=$(OHOS_SDK_HOME)/native/llvm/bin/$(OHOS_ARCH)-unknown-linux-ohos-clang AR=$(OHOS_SDK_HOME)/native/llvm/bin/llvm-ar RANLIB=$(OHOS_SDK_HOME)/native/llvm/bin/llvm-ranlib STRIP=$(OHOS_SDK_HOME)/native/llvm/bin/llvm-strip
	cd temp/openssl-3.5.0 && make -j $(shell nproc)
	cd temp/openssl-3.5.0 && make install_sw DESTDIR=$(shell pwd)/build
	mkdir -p ../buildroot
	$(OHOS_SDK_HOME)/native/llvm/bin/llvm-strip build/$(PREFIX)/lib/*.so
	rm -f ./build/$(PREFIX)/lib/*.a
	cp -rv ./build/$(PREFIX)/. ../buildroot | tee file.lst

download/openssl-3.5.0.tar.gz:
	mkdir -p download
	cd download && wget https://github.com/openssl/openssl/releases/download/openssl-3.5.0/openssl-3.5.0.tar.gz
