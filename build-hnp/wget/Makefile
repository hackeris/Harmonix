include ../utils/Makefrag

SOURCE_URL = $(GNU_MIRROR)/gnu/wget/wget-1.25.0.tar.gz
SOURCE_FILE = wget-1.25.0.tar.gz
SOURCE_DIR = wget-1.25.0
CONFIG_ARGS = --prefix=$(PREFIX) --host=$(OHOS_ARCH)-unknown-linux-musl --disable-shared --enable-static --with-ssl=openssl CFLAGS="-O2 -g -pipe -fstack-protector-strong -fno-omit-frame-pointer" CPPFLAGS="-I$(shell pwd)/../buildroot/include"

$(eval $(call define_autotools_package))
