Build an environment in an overlay directory on top of an existing "upstream" database
of installed packages.

## System requirements
- Linux 4.18+
- `fusermount`
- `unshare`

## Usage

It's advisable to build from a clean shell

```console
$ env -i TERM=$TERM PATH=/usr/bin:/bin sh
```

Then setup an environment and build it with:

```console
make spack.yaml # you may want to modify the specs
make build
```

this builds in `./store` and afterwards compresses that to `store.tar.zst`.

Next,

```console
make install
```

merges the new installs with the upstream database.

## Local testing and overriding variables

When you don't have slurm available, you can disable it with

```
env -i make SRUN= SRUN_BUILD= UPSTREAM_STORE=/path/to/your/spack/store build
```

See the full list of variables in [Make.inc](Make.inc)
