using BinaryBuilder

# Collection of sources required to build MbedTLS
# mbedtls release: 2.16.0
sources = [
    "https://github.com/ARMmbed/mbedtls.git" =>
    "fb1972db23da39bd11d4f9c9ea6266eee665605b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mbedtls
mkdir -p $prefix/lib
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DUSE_SHARED_MBEDTLS_LIBRARY=On
make -j${nproc} && make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libmbedcrypto", :libmbedcrypto),
    LibraryProduct(prefix, "libmbedx509", :libmbedx509),
    LibraryProduct(prefix, "libmbedtls", :libmbedtls)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
#build_tarballs(ARGS, src_name, src_version, sources, script, platforms, products, dependencies; kwargs...)
build_tarballs(ARGS, "MbedTLS", v"2.16.0", sources, script, platforms, products, dependencies)
