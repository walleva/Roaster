# ================================================================
# Compile LMDB
# ================================================================

[ -e $STAGE/lmdb ] && ( set -e
    cd $SCRATCH

    until git clone --depth 1 --no-checkout --no-single-branch $GIT_MIRROR/LMDB/lmdb.git; do echo 'Retrying'; done
    cd lmdb/libraries/liblmdb
    git checkout $(git tag | sed -n '/^LMDB_[0-9\.]*$/p' | sort -V | tail -n1)

    . scl_source enable devtoolset-7 || true

    make -j$(nproc)
    make test
    make install -j

    ldconfig &
    $IS_CONTAINER && ccache -C &
    cd
    rm -rf $SCRATCH/lmdb
    wait
)
rm -rvf $STAGE/lmdb
sync || true
