PKGS=zstd \
    zlib \
    pcre2 \
	libglib \
	qemu
STAMP=$(patsubst %,%/.stamp,$(PKGS))

all: copy

copy: harmonix-public.hnp
	rm -f ../entry/hnp/arm64-v8a/*.hnp
	cp $^ ../entry/hnp/arm64-v8a
	cp $^ ../entry/hnp/arm64-v8a/harmonix-public.hnp

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
