all: download/pcre2-10.45.tar.gz
	rm -rf temp build
	mkdir -p temp build
	cd temp && tar xvf ../download/pcre2-10.45.tar.gz
	cd temp/pcre2-10.45 && mkdir build
	cd temp/pcre2-10.45/build && PKG_CONFIG=/usr/bin/false cmake ../ -DPCRE2_BUILD_PCRE2_32=ON -DCMAKE_INSTALL_PREFIX=/data/app/harmonix.org/harmonix_1.0 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_C_COMPILER=$(OHOS_SDK_HOME)/native/llvm/bin/aarch64-unknown-linux-ohos-clang -DCMAKE_CXX_COMPILER=$(OHOS_SDK_HOME)/native/llvm/bin/aarch64-unknown-linux-ohos-clang -DCMAKE_BUILD_TYPE=RelWithDebInfo
	cd temp/pcre2-10.45/build && make -j $(shell nproc) && make install DESTDIR=$(shell pwd)/build
	mkdir -p ../buildroot
	cp -rfv build/data/app/harmonix.org/harmonix_1.0/. ../buildroot | tee file.lst

download/pcre2-10.45.tar.gz:
	mkdir -p download
	cd download && wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.45/pcre2-10.45.tar.gz
