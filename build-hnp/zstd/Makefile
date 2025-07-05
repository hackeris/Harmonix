all: download/zstd-1.5.7.tar.gz
	rm -rf temp build
	mkdir -p temp build
	cd temp && tar xvf ../download/zstd-1.5.7.tar.gz
	cd temp/zstd-1.5.7 && cat ../../0001-qsort.diff | patch -Np1
	cd temp/zstd-1.5.7 && mkdir build-zstd
	cd temp/zstd-1.5.7/build-zstd && PKG_CONFIG=/usr/bin/false cmake ../build/cmake -DCMAKE_INSTALL_PREFIX=/data/app/harmonix.org/harmonix_1.0 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_C_COMPILER=$(OHOS_SDK_HOME)/native/llvm/bin/aarch64-unknown-linux-ohos-clang -DCMAKE_CXX_COMPILER=$(OHOS_SDK_HOME)/native/llvm/bin/aarch64-unknown-linux-ohos-clang++ -DCMAKE_AR=$(OHOS_SDK_HOME)/native/llvm/bin/llvm-ar -DCMAKE_BUILD_TYPE=RelWithDebInfo -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=ON
	cd temp/zstd-1.5.7/build-zstd && make -j $(shell nproc) && make install DESTDIR=$(shell pwd)/build
	mkdir -p ../buildroot
	cp -rfv build/data/app/harmonix.org/harmonix_1.0/. ../buildroot | tee file.lst

download/zstd-1.5.7.tar.gz:
	mkdir -p download
	cd download && wget https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
