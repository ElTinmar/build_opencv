# Version: 20231006
# Image name: opencv-python-manylinux2014-x86-64

FROM quay.io/pypa/manylinux2014_x86_64:latest

ARG CCACHE_VERSION=3.7.9
ARG FFMPEG_VERSION=5.1.3
ARG FREETYPE_VERSION=2.13.2
ARG LIBPNG_VERSION=1.6.40
ARG NASM_VERSION=2.15.04
ARG OPENSSL_VERSION=1_1_1w
# 5.15.0 is hardcoded in opencv-python/patches/patchQtPlugins, so you better use that or modify the patch
ARG QT_VERSION=5.15.0 
ARG YASM_VERSION=1.3.0
ARG CUDA_VERSION_MAJOR=12
ARG CUDA_VERSION_MINOR=3
ARG CUDA_VERSION=$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR


ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH

# epel-release need for aarch64 to get openblas packages
RUN yum install zlib-devel curl-devel xcb-util-renderutil-devel xcb-util-devel xcb-util-image-devel xcb-util-keysyms-devel xcb-util-wm-devel mesa-libGL-devel libxkbcommon-devel libxkbcommon-x11-devel libXi-devel lapack-devel epel-release -y && \
    yum install openblas-devel dejavu-sans-fonts -y && \
    cp /usr/include/lapacke/lapacke*.h /usr/include/ && \
    curl https://raw.githubusercontent.com/xianyi/OpenBLAS/v0.3.3/cblas.h -o /usr/include/cblas.h 

# Install NVIDIA CUDA toolkit
RUN yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo && \
    yum clean all && \
    yum -y install cuda-toolkit-${CUDA_VERSION_MAJOR}-${CUDA_VERSION_MINOR}  

ENV PATH /usr/local/cuda-${CUDA_VERSION}/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH /usr/local/cuda-${CUDA_VERSION}/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

RUN mkdir ~/libpng_sources && \
    cd ~/libpng_sources && \
    curl -O -L https://download.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz && \
    tar -xf libpng-${LIBPNG_VERSION}.tar.gz && \
    cd libpng-${LIBPNG_VERSION} && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    cd .. && \
    rm -rf ~/libpng_sources

RUN mkdir ~/freetype_sources && \
    cd ~/freetype_sources && \
    curl -O -L https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz && \
    tar -xf freetype-${FREETYPE_VERSION}.tar.gz && \
    cd freetype-${FREETYPE_VERSION} && \
    ./configure --prefix="/ffmpeg_build" --enable-freetype-config && \
    make && \
    make install && \
    cd .. && \
    rm -rf ~/freetype_sources

RUN curl -O -L https://download.qt.io/official_releases/qt/5.15/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz && \
    tar -xf qt-everywhere-src-${QT_VERSION}.tar.xz && \
    cd qt-everywhere-src-${QT_VERSION} && \
    export MAKEFLAGS=-j$(nproc) && \
    ./configure -prefix /opt/Qt${QT_VERSION} -release -opensource -confirm-license -qtnamespace QtOpenCVPython -xcb -xcb-xlib -bundled-xcb-xinput -no-openssl -no-dbus -skip qt3d -skip qtactiveqt -skip qtcanvas3d -skip qtconnectivity -skip qtdatavis3d -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtimageformats -skip qtlocation -skip qtmultimedia -skip qtpurchasing -skip qtqa -skip qtremoteobjects -skip qtrepotools -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebsockets -skip qtwebview -skip xmlpatterns -skip declarative -make libs && \
    make && \
    make install && \
    cd .. && \
    rm -rf qt-everywhere*

ENV QTDIR /opt/Qt${QT_VERSION}
ENV PATH ${QTDIR}/bin:${PATH}

RUN mkdir ~/openssl_sources && \
    cd ~/openssl_sources && \
    curl -O -L https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSL_VERSION}.tar.gz && \
    tar -xf OpenSSL_${OPENSSL_VERSION}.tar.gz && \
    cd openssl-OpenSSL_${OPENSSL_VERSION} && \
    ./config --prefix="/ffmpeg_build" --openssldir="/ffmpeg_build" no-pinshared shared zlib && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    # skip installing documentation
    make install_sw && \
    cd .. && \
    rm -rf ~/openssl_build ~/openssl_sources

RUN mkdir ~/nasm_sources && \
    cd ~/nasm_sources && \
    curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.gz && \
    tar -xf nasm-${NASM_VERSION}.tar.gz && cd nasm-${NASM_VERSION} && ./autogen.sh && \
    ./configure --prefix="/ffmpeg_build" --bindir="/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/nasm_sources

RUN mkdir ~/yasm_sources && \
    cd ~/yasm_sources && \
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz && \
    tar -xf yasm-${YASM_VERSION}.tar.gz && \
    cd yasm-${YASM_VERSION} && \
    ./configure --prefix="/ffmpeg_build" --bindir="/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/yasm_sources

RUN mkdir ~/x264_sources && \
    cd ~/x264_sources && \
    git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git && \
    cd x264 && \
    ./configure --prefix="/ffmpeg_build" --bindir="/bin" --enable-shared && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/x264_sources

RUN mkdir ~/x265_sources && \
    cd ~/x265_sources && \
    git clone --branch stable --depth 2 https://bitbucket.org/multicoreware/x265_git && \
    cd x265_git/build/linux && \
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/ffmpeg_build" -DENABLE_SHARED:bool=on ../../source && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/x265_sources

RUN mkdir ~/libvpx_sources && \
    cd ~/libvpx_sources && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --prefix="/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm --enable-pic --enable-shared && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/libvpx_sources

RUN mkdir ~/nv_codec_sources && \
    cd ~/nv_codec_sources && \
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ~/nv_codec_sources

RUN mkdir ~/ffmpeg_sources && \
    cd ~/ffmpeg_sources && \
    curl -O -L https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    tar -xf ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    PATH=~/bin:$PATH && \
    PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig:/usr/local/lib/pkgconfig" ./configure --enable-nonfree --enable-gpl --enable-cuda-nvcc --enable-libnpp --enable-libx264 --enable-libx265 --prefix="/ffmpeg_build" --extra-cflags="-I/ffmpeg_build/include -I/usr/local/cuda-${CUDA_VERSION}/include" --extra-ldflags="-L/ffmpeg_build/lib -L/usr/local/cuda-${CUDA_VERSION}/lib64" --extra-libs="-lpthread -lm" --enable-openssl --enable-libvpx --disable-static --enable-shared --enable-pic --bindir="$HOME/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    echo "/ffmpeg_build/lib/" >> /etc/ld.so.conf && \
    ldconfig && \
    rm -rf ~/ffmpeg_sources

RUN curl -O -L https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}.tar.gz && \
    tar -xf ccache-${CCACHE_VERSION}.tar.gz && \
    cd ccache-${CCACHE_VERSION} && \
    ./configure && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd .. && \
    rm -rf ccache-*

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/ffmpeg_build/lib/:$QTDIR/lib
ENV LDFLAGS -L/ffmpeg_build/lib
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig:/ffmpeg_build/lib/pkgconfig
ENV CMAKE_ARGS "-DWITH_CUDA=ON -DENABLE_FAST_MATH=1 -DCUDA_FAST_MATH=1 -DBUILD_opencv_sfm=OFF -DWITH_FFMPEG=ON -DWITH_GTK=OFF -DWITH_QT=ON" 
ENV CI_BUILD=1 
ENV ENABLE_CONTRIB=1
ENV ENABLE_ROLLING=1

RUN mkdir ~/opencv_sources && \
    cd ~/opencv_sources && \
    git clone --recursive https://github.com/opencv/opencv-python.git && \
    cd opencv-python && \
    git submodule update --init --recursive --remote opencv && \
    /opt/python/cp39-cp39/bin/pip wheel . --verbose

RUN TOOLS_PATH=/opt/_internal/pipx/venvs/auditwheel && \
    source $TOOLS_PATH/bin/activate && \
    python patch_auditwheel_whitelist.py && \
    deactivate

RUN auditwheel repair opencv_contrib_python_rolling-4.8.0.20231220-cp39-cp39-linux_x86_64.whl
