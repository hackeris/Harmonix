PKGS=zstd \
	zlib \
    pcre2 \
	libglib \
	qemu-10
STAMP=$(patsubst %,%/.stamp,$(PKGS))

all: copy

copy: harmonix-public.hnp
	rm -f ../entry/hnp/$(OHOS_ABI)/*.hnp
	cp $^ ../entry/hnp/$(OHOS_ABI)/harmonix-private.hnp
	cp $^ ../entry/hnp/$(OHOS_ABI)/harmonix-public.hnp

harmonix-public.hnp: $(STAMP) Makefile
	# reduce size
	mkdir -p sysroot/bin
	mkdir -p sysroot/lib
	cp -r buildroot/lib/libz.so* sysroot/lib/
	cp -r buildroot/lib/libglib-2.0.so* sysroot/lib/
	cp -r buildroot/lib/libgmodule-2.0.so* sysroot/lib/
	cp -r buildroot/lib/libintl.so* sysroot/lib/
	cp -r buildroot/lib/libpcre2-8.so* sysroot/lib/
	cp -r buildroot/bin/qemu-* sysroot/bin/
	cp -r buildroot/bin/harmonix sysroot/bin/
	# create hnp manually
	cp hnp.json sysroot
	rm -f harmonix-public.hnp
	zip -r harmonix-public.hnp sysroot

%/.stamp: %/Makefile
	make -C $(patsubst %/.stamp,%,$@)
	touch $@

rebuild-%:
	make -C $(patsubst rebuild-%,%,$@)
	touch $(patsubst rebuild-%,%/.stamp,$@)

clean:
	rm -f $(STAMP)
	rm -rf buildroot
	rm -rf sysroot
