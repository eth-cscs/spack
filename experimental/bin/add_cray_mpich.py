#!/usr/bin/env spack-python

# this just adds cray-mpich as a package to the store.
# currently very piz daint-specific.

from spack.spec import Spec
import spack.store
import spack.compilers
import spack.environment

for compiler in spack.compilers.all_compilers():
    if compiler.name == 'gcc':
        spec = Spec('cray-mpich@7.7.18 target=x86_64')
        spec.external_path = '/opt/cray/pe/mpt/7.7.18/gni/mpich-gnu'
        spec.compiler = compiler.spec
        spec.concretize()
        spack.store.db.add(spec, directory_layout=None, explicit=True)
