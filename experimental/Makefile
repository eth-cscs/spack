include $(CURDIR)/Make.inc

.PHONY: clean

all: build

# Install overlayfs from the official binaries distributed on Github, cause
# unclear if available by default.
deps/usr/bin/overlayfs:
	mkdir -p $(dir $@)
	$(CURL) -Lfso $(notdir $@) https://github.com/containers/fuse-overlayfs/releases/download/v1.8.2/fuse-overlayfs-x86_64
	echo "d7488446d5a17586a4aa3cc15e21d675a04a04f553e031c7789ed5e83ec4d829 overlayfs" | sha256sum --check
	mv $(notdir $@) $@
	chmod +x $@

deps/usr/bin/zstd:
	mkdir -p $(dir $@)
	$(CURL) -Lfso zstd.tar.gz https://github.com/JuliaBinaryWrappers/Zstd_jll.jl/releases/download/Zstd-v1.5.2%2B0/Zstd.v1.5.2.x86_64-linux-gnu.tar.gz
	echo "9d0fff908e3e0273cc8360a3fb4696e4227bc5cd0dd10bd3a4c9d295b9e4e25e zstd.tar.gz" | sha256sum --check
	tar -xf zstd.tar.gz -C deps/usr
	rm -f zstd.tar.gz

# Install our hopefully working fork of Spack
deps/spack:
	mkdir -p $(dir $@)
	$(GIT) clone --depth=1 --branch=develop https://github.com/eth-cscs/spack.git $@

# Setup the environment
spack.yaml: deps/spack
	cp $(CURDIR)/../environments/daint/spack.yaml $@

# Ensure that cray-mpich is in the database so it can use --reuse'd.
add_cray_mpich: bin/add_cray_mpich.py spack.yaml deps/spack
	$(SRUN) $(SPACK) \
		-e $(CURDIR) \
		-c "config:install_tree:root:$(DOWNSTREAM_STORE)" \
		python $< && touch "$@"

# Concretize
spack.lock: spack.yaml deps/spack add_cray_mpich
	$(SRUN) $(SPACK) -e $(CURDIR) concretize --reuse

# Distributed build using overlayfs.
# Spack believes it's installing to UPSTREAM_STORE, but in reality it's installing new
# packages to `DOWNSTREAM_STORE`.
build: spack.lock deps/usr/bin/overlayfs add_cray_mpich
	# Not sure if really required, but to avoid having to bind mount
	# the merged dir over the bottom layer, add a level of indirection with a
	# symlink from $(UPSTREAM_STORE) to $(UPSTREAM_STORE)-current
	if [ "$$(realpath $(UPSTREAM_STORE)-current)" != "$$(realpath $(UPSTREAM_STORE))" ]; then \
		echo "Make sure `$(UPSTREAM_STORE)-current` is a symlink to `$(UPSTREAM_STORE)`" \
		exit 1 \
	fi
	mkdir -p $(UPSTREAM_STORE)-current $(UPSTREAM_STORE) $(DOWNSTREAM_STORE) work merged
	$(SRUN_BUILD) \
		$(OVERLAY_SH) $(OVERLAYFS) $(UPSTREAM_STORE)-current $(DOWNSTREAM_STORE) $(CURDIR)/work $(CURDIR)/merged \
		$(UNSHARE) -rm \
			$(BIND_SH) $(CURDIR)/merged $(UPSTREAM_STORE) \
			$(SPACK) \
				-c "config:install_tree:root:$(UPSTREAM_STORE)" \
				-c "modules:default:enable::[]" \
				-e $(dir $<) \
				install -j32 && touch "$@"

# Create a layer, including the new database index
store.tar.zst: exclude.txt build deps/usr/bin/zstd
	tar -I "$(ZSTD) -9 -T0" -X $< -cf $@ -C $(DOWNSTREAM_STORE) .

# Installing comes down to merging `DOWNSTREAM_STORE` with `UPSTREAM_STORE`
install: store.tar.zst build deps/usr/bin/zstd
	tar -I $(ZSTD) -xf $< -C $(UPSTREAM_STORE)

clean:
	rm -rf -- deps build $(DOWNSTREAM_STORE) work merged .spack spack.yaml \
	          spack.lock .spack-env store.tar.zst
