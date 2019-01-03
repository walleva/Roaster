# ================================================================
# Compile NCCL
# ================================================================

[ -e $STAGE/nccl ] && ( set -xe
    cd $SCRATCH
    
    # ------------------------------------------------------------

    . "$ROOT_DIR/pkgs/utils/git/version.sh" NVIDIA/nccl,v
    until git clone --depth 1 --single-branch -b "$GIT_TAG" "$GIT_REPO"; do echo 'Retrying'; done
    cd nccl

    git submodule add -b master "$GIT_MIRROR/NVIDIA/nccl-tests.git"
    git commit -am "Add nccl-tests as submodule."

    # ------------------------------------------------------------

    . "$ROOT_DIR/pkgs/utils/fpm/pre_build.sh"

    (
        set +xe
        . scl_source enable devtoolset-7
        set -xe

        . "$ROOT_DIR/pkgs/utils/fpm/toolchain.sh"

        export CXX="$TOOLCHAIN/g++"
        export CXXFLAGS="-fdebug-prefix-map='$SCRATCH'='$INSTALL_PREFIX/cuda/src' -g"

        # Inject CXXFLAGS via GCOV_FLAGS
        make src.build GCOV_FLAGS="$CXXFLAGS" -j$(nproc)
        make src.install PREFIX="$INSTALL_ABS/cuda" -j

        pushd nccl-tests
        make src.build NCCL_HOME="$INSTALL_ABS/cuda" -j$(nproc)
        mkdir -p "${INSTALL_ABS}/cuda/bin/"
        install build/* "$_"
        for i in $(ls build); do
            "build/$i" -g 1
            for data_type in int8 int32 int64 half float double; do
                LD_LIBRARY_PATH="$INSTALL_ABS/cuda/lib:$LD_LIBRARY_PATH" "build/$i" -b 8 -e 256M -f 2 -g 1 -d "$data_type" || true
            done
        done
        popd

        mv -f "$INSTALL_ABS/cuda/lib"{,64}
    )

    "$ROOT_DIR/pkgs/utils/fpm/install_from_git.sh"

    # ------------------------------------------------------------

    cd
    rm -rf $SCRATCH/nccl
)
sudo rm -vf $STAGE/nccl
sync || true