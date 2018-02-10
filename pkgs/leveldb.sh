# ================================================================
# Compile LevelDB
# ================================================================

[ -e $STAGE/leveldb ] && ( set -e
    cd $SCRATCH

    until git clone --depth 1 --no-checkout --no-single-branch $GIT_MIRROR/google/leveldb.git; do echo 'Retrying'; done
    cd leveldb
    git checkout $(git tag | sed -n '/^v[0-9\.]*$/p' | sort -V | tail -n1)

    . scl_source enable devtoolset-7 || true

    make -j$(nproc)
    make check -j$(nproc)
    mkdir -p /usr/local/include/leveldb/
    install include/leveldb/*.h $_
    mkdir -p /usr/local/lib
    install out-*/libleveldb.* $_

    ldconfig &
    $IS_CONTAINER && ccache -C &
    cd
    rm -rf $SCRATCH/leveldb
    wait
)
rm -rvf $STAGE/leveldb
sync || true
