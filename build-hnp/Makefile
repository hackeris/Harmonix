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
	rm -rfv sysroot/share/man
	rm -rfv sysroot/share/doc
	rm -rfv sysroot/share/info
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
