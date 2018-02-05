# ================================================================
# Compile OpenCV
# ================================================================

[ -e $STAGE/opencv ] && ( set -e
    cd $SCRATCH

    until git clone --depth 1 --no-single-branch $GIT_MIRROR/opencv/opencv.git; do echo 'Retrying'; done
    cd opencv
    # git checkout $(git tag | sed -n '/^[0-9\.]*$/p' | sort -V | tail -n1)

    . scl_source enable devtoolset-6 || true

    mkdir -p build
    cd $_

    if [ $GIT_MIRROR == $GIT_MIRROR_CODINGCAFE ]; then
        export HTTP_PROXY=proxy.codingcafe.org:8118
        [ $HTTP_PROXY ] && export HTTPS_PROXY=$HTTP_PROXY
        [ $HTTP_PROXY ] && export http_proxy=$HTTP_PROXY
        [ $HTTPS_PROXY ] && export https_proxy=$HTTPS_PROXY
    fi
    cmake                                               \
        -G"Ninja"                                       \
        -DBUILD_opencv_dnn=OFF                          \
        -DBUILD_opencv_world=OFF                        \
        -DCMAKE_BUILD_TYPE=Release                      \
        -DCMAKE_INSTALL_PREFIX=/usr/local               \
        -DCMAKE_VERBOSE_MAKEFILE=ON                     \
        -DCPACK_BINARY_DEB=OFF                          \
        -DCPACK_BINARY_RPM=ON                           \
        -DCPACK_BINARY_STGZ=OFF                         \
        -DCPACK_BINARY_TBZ2=OFF                         \
        -DCPACK_BINARY_TGZ=OFF                          \
        -DCPACK_BINARY_TXZ=OFF                          \
        -DCPACK_BINARY_TZ=OFF                           \
        -DCPACK_SET_DESTDIR=ON                          \
        -DCPACK_SOURCE_RPM=ON                           \
        -DCPACK_SOURCE_STGZ=OFF                         \
        -DCPACK_SOURCE_TBZ2=OFF                         \
        -DCPACK_SOURCE_TGZ=OFF                          \
        -DCPACK_SOURCE_TXZ=OFF                          \
        -DCPACK_SOURCE_ZIP=OFF                          \
        -DCUDA_NVCC_FLAGS='--expt-relaxed-constexpr'    \
        -DENABLE_CXX11=ON                               \
        -DINSTALL_CREATE_DISTRIB=ON                     \
        -DOPENCV_ENABLE_NONFREE=ON                      \
        -DWITH_LIBV4L=ON                                \
        -DWITH_NVCUVID=ON                               \
        -DWITH_OPENGL=ON                                \
        -DWITH_OPENMP=ON                                \
        -DWITH_QT=ON                                    \
        -DWITH_TBB=ON                                   \
        -DWITH_UNICAP=ON                                \
        ..

    if $IS_CONTAINER; then
        time cmake --build . --target install
    else
        time cmake --build . --target package
        yum install -y ./OpenCV*.rpm || yum update -y ./OpenCV*.rpm || rpm -ivh --nodeps ./OpenCV*.rpm || rpm -Uvh --nodeps ./OpenCV*.rpm
    fi

    cd
    rm -rf $SCRATCH/opencv
    wait
)
rm -rvf $STAGE/opencv
sync || true
