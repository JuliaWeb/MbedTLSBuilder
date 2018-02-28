using BinaryBuilder

# Collection of sources required to build MbedTLS
sources = [
    "https://github.com/ARMmbed/mbedtls.git" =>
    "d1236a790ea0c685e136e9a72b4666882119d3f6",

]

# Bash recipe for building across all platforms
script = raw"""
if [ $target != "i686-w64-mingw32" ]; then
cd $WORKSPACE/srcdir
cd mbedtls/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DUSE_SHARED_MBEDTLS_LIBRARY=On
make && make install

else
cd $WORKSPACE/srcdir
cd mbedtls/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/x86_64-linux-gnu/x86_64-linux-gnu.toolchain WINDOWS_BUILDE=1  -DUSE_SHARED_MBEDTLS_LIBRARY=On
export WINDOWS_BUILD=1
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/x86_64-linux-gnu/x86_64-linux-gnu.toolchain WINDOWS_BUILD=1  -DUSE_SHARED_MBEDTLS_LIBRARY=On
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/x86_64-linux-gnu/x86_64-linux-gnu.toolchain  -DUSE_SHARED_MBEDTLS_LIBRARY=On WINDOWS_BUILD=1
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/x86_64-linux-gnu/x86_64-linux-gnu.toolchain  -DUSE_SHARED_MBEDTLS_LIBRARY=On
make WINDOWS_BUILD=1 && make install
cd $prefix/lib
ls
cd /workspace/srcdir/mbedtls/
ls
cd include
ls
cd mbedtls/
ls
vim config.h 
nano config.h 
vi config.h 
ls
cd ..
ls
cd ..
ls
vi Makefile 
vi CMakeLists.txt 
ls
cat cmake_install.cmake 
ls
cd CMakeFiles/
ls
cd ..
ls

fi

if [ $target = "x86_64-apple-darwin14" ]; then
cd $WORKSPACE/srcdir
cd /opt
ls
cd x86_64-apple-darwin14/
ls
cd x86_64-apple-darwin14
ls
cd lib
ls
cd ..
ls
cd ..
ls
cd MacOSX10.10.sdk/
ls
cd usr
ls
cd bin
ls
cd ..
ls
cd libexec/
ls
cd ..
ls
cd share
ls
cd ..
cd include/
ls
ls
cd ..
ls
cd ..
cd ..
ls
cd sahre
ls
cd share
ls
cd ..
ls
cd libexec/
ls
cd gcc
ls
cd x86_64-apple-darwin14/
ls
cd 7.3.0/
ls
cd ../..
cd ..
cd ..
ls
cat x86_64-apple-darwin14
cat x86_64-apple-darwin14.toolchain 

fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    BinaryProvider.Linux(:i686, :glibc),
    BinaryProvider.Linux(:x86_64, :glibc),
    BinaryProvider.Linux(:aarch64, :glibc),
    BinaryProvider.Linux(:armv7l, :glibc),
    BinaryProvider.Linux(:powerpc64le, :glibc),
    BinaryProvider.Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = Product[
    LibraryProduct(prefix, "libmbedcrypto", :libmbedcrypto),
    LibraryProduct(prefix, "libmbedtls", :libmbedtls),
    LibraryProduct(prefix, "libmbedx509", :libmbedx509)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Parse out some command-line arguments
BUILD_ARGS = ARGS

# This sets whether we should build verbosely or not
verbose = "--verbose" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--verbose", BUILD_ARGS)

# This flag skips actually building and instead attempts to reconstruct a
# build.jl from a GitHub release page.  Use this to automatically deploy a
# build.jl file even when sharding targets across multiple CI builds.
only_buildjl = "--only-buildjl" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--only-buildjl", BUILD_ARGS)

if !only_buildjl
    # If the user passed in a platform (or a few, comma-separated) on the
    # command-line, use that instead of our default platforms
    if length(BUILD_ARGS) > 0
        platforms = platform_key.(split(BUILD_ARGS[1], ","))
    end
    info("Building for $(join(triplet.(platforms), ", "))")

    # Build the given platforms using the given sources
    autobuild(pwd(), "MbedTLS", platforms, sources, script, products;
                                      dependencies=dependencies, verbose=verbose)
else
    # If we're only reconstructing a build.jl file on Travis, grab the information and do it
    if !haskey(ENV, "TRAVIS_REPO_SLUG") || !haskey(ENV, "TRAVIS_TAG")
        error("Must provide repository name and tag through Travis-style environment variables!")
    end
    repo_name = ENV["TRAVIS_REPO_SLUG"]
    tag_name = ENV["TRAVIS_TAG"]
    product_hashes = product_hashes_from_github_release(repo_name, tag_name; verbose=verbose)
    bin_path = "https://github.com/$(repo_name)/releases/download/$(tag_name)"
    dummy_prefix = Prefix(pwd())
    print_buildjl(pwd(), products(dummy_prefix), product_hashes, bin_path)

    if verbose
        info("Writing out the following reconstructed build.jl:")
        print_buildjl(STDOUT, product_hashes; products=products(dummy_prefix), bin_path=bin_path)
    end
end

if !isempty(get(ENV,"TRAVIS_TAG",""))
    print_buildjl(pwd(), products, hashes,
        "https://github.com/quinnj/MbedTLSBuilder/releases/download/$(ENV["TRAVIS_TAG"])")
end

