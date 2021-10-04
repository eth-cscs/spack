Fork of [Spack][spack] with a slower update cadence to the [`develop` branch][cscs-develop].

[`cscs-eths/spack` ↔️ `spack/spack` comparison][compare]

## Setup Spack from this fork

```console
git clone -b develop -c feature.manyFiles=true https://github.com/eth-cscs/spack.git
cd spack/bin
./spack install zlib
```

## Updates

Updates work more or less automatic. A scheduled pipeline bisects the upstream
`develop` branch to the latest working version and opens an issue with a request to
update to the corresponding commit SHA.

Then a [Github action][action] is run by hand with the corresponding commit SHA to sync
the repository.

## What's in this branch?

1. [`config/<name>`](config/) contains config for system `<name>`;
2. [`environments/<name>/spack.yaml`](environments/) is an environment file with a list of
   packages part of the available applications of CSCS. These environment files include
   the system config files;
3. [`patches`](patches/) contains some patches for Spack itself that are not upstreamed.

[action]: https://github.com/eth-cscs/spack/actions/workflows/mirror.yaml
[compare]: https://github.com/eth-cscs/spack/compare/develop...spack:develop
[cscs-develop]: https://github.com/eth-cscs/spack/tree/develop
[spack]: https://github.com/spack/spack