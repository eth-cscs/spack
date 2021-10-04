# This is where the system spack db lives
UPSTREAM_STORE:=/apps/daint/UES/jenscscs/store

# Where to build new packages
DOWNSTREAM_STORE:=$(CURDIR)/store

# Basic `srun` command (for concretization)
SRUN:=srun --pty -Ajenscscs -Cmc -N1

# `srun` command for distributed builds
SRUN_BUILD:=$(SRUN) -n8 -c32 --overcommit --oversubscribe

GIT:=git
CURL:=curl
UNSHARE:=unshare

# Managed executables
SPACK:=$(CURDIR)/deps/spack/bin/spack
OVERLAYFS:=$(CURDIR)/deps/usr/bin/overlayfs
ZSTD:=$(CURDIR)/deps/usr/bin/zstd
BIND_SH:=$(CURDIR)/bin/bind.sh
OVERLAY_SH:=$(CURDIR)/bin/overlay.sh

# Make tools available and make sure Spack config is local
export SPACK_USER_CACHE_PATH:=$(CURDIR)/.spack
export SPACK_USER_CONFIG_PATH:=$(CURDIR)/.spack
