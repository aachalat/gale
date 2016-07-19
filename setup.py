
#  Copyright 2016 Andrew Chalaturnyk
#
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


def meta_info():
    name="galxe"

    description="graph algorithm c extensions for python"
    long_description="""
    Various algorithms from graph theory.

    Using a c library and cython to create python extension classes.

    Started as a re-imagining of thesis work from:
    https://github.com/aachalat/hamilton_cycle.git

    """

    author="Andrew Chalaturnyk"
    author_email="code.aachalat@gmail.com"
    maintainer=author
    maintainer_email=author_email

    url="https://github.com/aachalat/galxe.git"
    license="Apache License, Version 2.0"

    classifiers=[
        "Development Status :: 2 - Pre-Alpha",
        "License :: OSI Approved :: Apache Software License",
        "Intended Audience :: Science/Research",
        "Intended Audience :: Education",
        "Intended Audience :: Developers",
        "Programming Language :: C",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Programming Language :: Python :: Implementation :: CPython",
        "Topic :: Education",
        "Topic :: Scientific/Engineering :: Mathematics",
        "Operating System :: POSIX",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: POSIX :: Linux",
    ]

    return vars()

import os
import sys
from os.path import join, split, isfile, dirname, splitext

from distutils.core import setup
from distutils.extension import Extension
from distutils.command.build_ext import build_ext as _build_ext
from distutils import sysconfig
from distutils import log


# check for file existance before chdir called
_is_full_source_tree = isfile(join(dirname(__file__),"MANIFEST.in"))

with open(join(dirname(__file__), "galxe", "VERSION")) as f:
    VERSION = f.read().strip()

#make sure setup works as expected:  TODO: maybe remove this
if __name__=="__main__" and dirname(__file__): os.chdir(dirname(__file__))

def _mock_cythonize(args):
        #todo: convert strings into Extensions w/ correct project/file name
        #todo: fail if a c file is missing
        log.warn("...mock cythonizing Extension instances...")
        strip_pyx=lambda x:x[:-3]+"c" if x.lower().endswith(".pyx") else x
        for i in args:
            if isinstance(i, Extension):
                i.sources[:]=[strip_pyx(x) for x in i.sources]
                log.warn("\tusing: %s  for: %s", i.sources,i.name)
        return args

if _is_full_source_tree:
    # using the full source tree (not in a source distribution)
    try:
        #raise ImportError
        from Cython.Build import cythonize
    except ImportError:
        def cythonize(args):
            log.warn("Cython missing, trying to use existing c files instead.")
            return _mock_cythonize(args)
else:
    def cythonize(args):
        log.warn("using a source distribution. cython files are not included.")
        return _mock_cythonize(args)

if sys.platform == 'darwin':
    no_warn = ["-Wno-unused-function", "-Wno-unneeded-internal-declaration"]
    CV = sysconfig.get_config_vars()
    CV['CFLAGS'] = " ".join(CV['CFLAGS'].split() + no_warn)

class build_ext(_build_ext):
    def finalize_options(self):
        _build_ext.finalize_options(self)
        if self.inplace:
          for x in self.distribution.packages:
            self.library_dirs.append(x)
        else:
          self.library_dirs.append(self.build_lib)
          for x in self.distribution.packages:
              self.library_dirs.append(join(self.build_lib,x))
        if sys.platform.lower().startswith("linux"):
            # allow shared library to be found in same folder as
            # dependant module
            for x in self.extensions:
                if len(x.libraries): x.runtime_library_dirs=["$ORIGIN"]
        #fix extension dependancies:
        for x in self.extensions:
            if len(x.libraries):
                for y in x.libraries:
                    for z in self.extensions:
                        zname = z.name.split('.')[-1]
                        if z is not x and zname.startswith("lib"+y):
                            p = []
                            if not self.inplace:
                                p.extend(split(self.build_lib))
                            p.extend(z.name.split('.')[:-1])
                            fn = self.get_ext_filename(zname)
                            if sys.platform == 'darwin':
                                fn, _ = splitext(fn)
                                fn += ".dylib"
                            p.append(fn)
                            x.depends.append(join(*p))

    if sys.platform == 'darwin':
        # intercept module building to allow for shared library ("lib" prefix)
        # to be used on osx (normally a mach-O bundle/module is made and
        # linking directly does not work )

        class patch_compiler:
            def __init__(x, c):
                x.c = c
            def __enter__(x):
                c = x.c
                log.warn('storing compiler settings')
                x.old = list(c.linker_so), c.shared_lib_extension, CV['SO']
            def __exit__(x, type, value, traceback):
                c = x.c
                log.warn('restoring compiler settings')
                c.linker_so, c.shared_lib_extension, CV['SO'] = x.old

        def build_extension(self, ext):
            if ext.name.split('.')[-1].startswith('lib'):
                with self.patch_compiler(self.compiler):
                    self.compiler.shared_lib_extension = ".dylib"
                    CV['SO'] = ".dylib"
                    self.compiler.linker_so[:] = [
                            x.replace('-bundle', '-dynamiclib')
                                for x in self.compiler.linker_so]
                    ext.extra_link_args.extend([
                          "-install_name",
                          "@loader_path/%s"
                                % split(self.get_ext_filename(ext.name))[-1]])
                    log.info(
                        "patched linker options for dylib: %s"
                            % self.get_ext_filename(ext.name))
                    return _build_ext.build_extension(self, ext)
            return _build_ext.build_extension(self, ext)

include_dirs = ["lib/include"]

ext_modules = [
    #using distutils build_ext to make a shared library in the galxe package
    Extension(
        "galxe.libgalxe_support",
        sources=["lib/graph_core.c", "lib/graph_dfs.c"],
        include_dirs=include_dirs,)
]

pyx_modules = [
    Extension("galxe.graph", sources=["galxe/graph.pyx"],
               libraries=["galxe_support"],
               include_dirs=include_dirs),
    Extension("galxe.utils", sources=["galxe/utils.pyx"],
               include_dirs=include_dirs),
    Extension("galxe.core", sources=["galxe/core.pyx"],
               include_dirs=include_dirs),
    Extension("galxe.dfs", sources=["galxe/dfs.pyx"],
               libraries=["galxe_support"],
               include_dirs=include_dirs),
    Extension("galxe.hamcycle", sources=["galxe/hamcycle.pyx"],
           libraries=["galxe_support"],
           include_dirs=include_dirs),
]

ext_modules.extend(cythonize(pyx_modules))

if __name__ == "__main__":

  setup(
      packages=["galxe"],
      package_data={"galxe":["VERSION"]},
      ext_modules=ext_modules,
      cmdclass = {'build_ext':build_ext},
      version=VERSION,
      **meta_info()
  )
