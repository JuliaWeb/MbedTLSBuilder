using BinaryBuilder

# Collection of sources required to build MbedTLS
sources = [
    "https://github.com/ARMmbed/mbedtls.git" =>
    "d1236a790ea0c685e136e9a72b4666882119d3f6",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mbedtls/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DUSE_SHARED_MBEDTLS_LIBRARY=On
make && make install
if [ $target == "x86_64-w64-mingw32" ]; then
    cp $prefix/lib/*.dll $prefix/bin/.
elif [ $target == "i686-w64-mingw32" ]; then
    cp $prefix/lib/*.dll $prefix/bin/.
else
    cd $prefix/lib; for f in $(find . -name '*.so'); do strip $f ; done
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc),
    Linux(:powerpc64le, :glibc),
    Windows(:x86_64),
    Windows(:i686),
    MacOS()
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libmbedcrypto", :libmbedcrypto),
    LibraryProduct(prefix, "libmbedtls", :libmbedtls),
    LibraryProduct(prefix, "libmbedx509", :libmbedx509)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "MbedTLS", sources, script, platforms, products, dependencies)
