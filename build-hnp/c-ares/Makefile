include ../utils/Makefrag

SOURCE_URL = https://github.com/c-ares/c-ares/releases/download/v1.34.5/c-ares-1.34.5.tar.gz
SOURCE_FILE = c-ares-1.34.5.tar.gz
SOURCE_DIR = c-ares-1.34.5
CMAKE_ARGS = -DCMAKE_INSTALL_PREFIX=$(PREFIX) -DCARES_STATIC=OFF -DCARES_SHARED=ON -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=$(OHOS_ARCH) -DCMAKE_BUILD_TYPE=RelWithDebInfo

$(eval $(call define_cmake_package))
