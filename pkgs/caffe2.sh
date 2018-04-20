# ================================================================
# Compile Caffe2
# ================================================================

[ -e $STAGE/caffe2 ] && ( set -xe
    cd $SCRATCH

    # ------------------------------------------------------------

    until git clone --depth 1 $GIT_MIRROR/pytorch/pytorch.git; do echo 'Retrying'; done
    cd pytorch

    if [ $GIT_MIRROR == $GIT_MIRROR_CODINGCAFE ]; then
        export HTTP_PROXY=proxy.codingcafe.org:8118
        [ $HTTP_PROXY ] && export HTTPS_PROXY=$HTTP_PROXY
        [ $HTTP_PROXY ] && export http_proxy=$HTTP_PROXY
        [ $HTTPS_PROXY ] && export https_proxy=$HTTPS_PROXY
        for i in ARM-software facebook{,incubator} glog google Maratyszcza NervanaSystems nvidia NVlabs onnx pybind RLovelett zdevito; do
            sed -i "s/[^[:space:]]*:\/\/[^\/]*\(\/$i\/.*\)/$(sed 's/\//\\\//g' <<<$GIT_MIRROR )\1.git/" .gitmodules
            sed -i "s/\($(sed 's/\//\\\//g' <<<$GIT_MIRROR )\/$i\/.*\.git\)\.git[[:space:]]*$/\1/" .gitmodules
        done
    fi

    git submodule init
    until git config --file .gitmodules --get-regexp path | cut -d' ' -f2 | parallel -j0 --ungroup --bar 'git submodule update --recursive {}'; do echo 'Retrying'; done

    pushd modules/rocksdb
    if [ $(sed -n '/#include[[:space:]][[:space:]]*["<]caffe2\/core\/module\.h[">][[:space:]]*$/p' rocksdb.cc | wc -l) -le 0 ]; then
        echo '#include "caffe2/core/module.h"' > .rocksdb.cc
        cat rocksdb.cc >> .rocksdb.cc
        mv -f {.,}rocksdb.cc
    fi
    popd

    # ------------------------------------------------------------

    . "$ROOT_DIR/pkgs/utils/fpm/pre_build.sh"

    (
        set +x
        # Currently caffe2 can only be built with gcc-5.
        # CUDA 9.1 only support up to gcc-6.3.0 while devtoolset-6 contains gcc-6.3.1
        # TODO: Upgrade glog to use new compiler when possible.
        . scl_source enable devtoolset-6 || true
        set -xe

        . "$ROOT_DIR/pkgs/utils/fpm/toolchain.sh"

        mkdir -p build
        cd $_

        # ln -sf $(which ninja-build) /usr/bin/ninja

        export MPI_HOME=/usr/local/openmpi

        # Some platform (i.e. macOS) may need -DCUDA_ARCH_NAME=Pascal
        #
        # TODO: ATen support currently result in 100+GB binaries in total.
        cmake                                       \
            -DBENCHMARK_ENABLE_LTO=ON               \
            -DBENCHMARK_USE_LIBCXX=OFF              \
            -DBLAS=MKL                              \
            -DCMAKE_BUILD_TYPE=Release              \
            -DCMAKE_C_COMPILER="$TOOLCHAIN/cc"      \
            -DCMAKE_C{,XX}_FLAGS="-g"               \
            -DCMAKE_CXX_COMPILER="$TOOLCHAIN/c++"   \
            -DCMAKE_INSTALL_PREFIX="$INSTALL_ABS"   \
            -DCMAKE_VERBOSE_MAKEFILE=ON             \
            -DCPUINFO_BUILD_TOOLS=ON                \
            -DUSE_ATEN=OFF                          \
            -DUSE_NATIVE_ARCH=ON                    \
            -DUSE_OPENMP=ON                         \
            -DUSE_ROCKSDB=ON                        \
            -DUSE_ZMQ=ON                            \
            -DUSE_ZSTD=OFF                          \
            -G"Ninja"                               \
            ..

        time cmake --build .
        time cmake --build . --target test || ! nvidia-smi || true
        time cmake --build . --target install

        # rm -rf /usr/bin/ninja

        # --------------------------------------------------------
        # Tag with version detected from cmake cache
        # --------------------------------------------------------

        cmake -LA -N . | sed -n 's/^CAFFE2_VERSION:.*=//p' | xargs git tag -f

        # --------------------------------------------------------
        # Expose site-packages
        # --------------------------------------------------------

        pushd "$INSTALL_ROOT"
        # Do not move the "usr/" outside of "{}" because glob "*" relies on it.
        for i in "usr/lib/python"*"/site-packages"; do
        for j in caffe{,2}; do
            ln -sf {$i,usr/local}/$j
        done
        done
        popd
    )

    "$ROOT_DIR/pkgs/utils/fpm/install_from_git.sh"
    
    # ------------------------------------------------------------

    cd
    rm -rf $SCRATCH/pytorch

    # ------------------------------------------------------------

    $ISCONTAINER || parallel -j0 --bar --line-buffer 'bash -c '"'"'
        echo N | python -m caffe2.python.models.download -i {}
    '"'" :::                    \
        bvlc_{alexnet,googlenet,reference_{caffenet,rcnn_ilsvrc13}} \
        densenet121             \
        finetune_flickr_style   \
        inception_v{1,2}        \
        resnet50                \
        shufflenet              \
        squeezenet              \
        vgg{16,19}
)
sudo rm -vf $STAGE/caffe2
sync || true
