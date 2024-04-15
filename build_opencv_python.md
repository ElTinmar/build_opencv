# Why would you want to compile opencv yourself ?

- extra codecs
- CUDA support
- TODO build audited manylinux wheel (check https://github.com/opencv/opencv-python/blob/4.x/docker/manylinux2014/Dockerfile_x86_64)
  
# NVIDIA

* NVIDIA CUDA Toolkit

Choose the right CUDA version 
```
export CUDA_VERSION=12.3
```

Remove exisiting packages

```
sudo apt clean
sudo apt update
sudo apt purge cuda
sudo apt purge nvidia-*
sudo apt autoremove
```

Install cuda toolkit from nvidia

```
sudo apt-get install linux-headers-$(uname -r)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-${CUDA_VERSION}
```

Reboot.

check https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions

```
export PATH=/usr/local/cuda-${CUDA_VERSION}/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
 ```

# Install dependencies

```
sudo apt install build-essential cmake pkg-config unzip yasm git checkinstall \
libjpeg-dev libpng-dev libtiff-dev \
libxvidcore-dev x264 libx264-dev libfaac-dev libmp3lame-dev libtheora-dev \
libfaac-dev libmp3lame-dev libvorbis-dev libva-dev libx265-dev libnuma-dev \
libtbb-dev libatlas-base-dev gfortran \
libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
libopenblas-dev liblapack-dev libeigen3-dev python3-dev libhdf5-dev
```

# Compile FFMPEG (optional)

Install NVIDIA codec headers for NVENC/NVDEC support (by default installs ffnvcodec.pc in /usr/local/lib/pkgconfig)
(ref https://docs.nvidia.com/video-technologies/video-codec-sdk/12.1/ffmpeg-with-nvidia-gpu/index.html)

```
cd ~/Downloads
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
sudo make install
```

Configure FFMPEG with NVENC/NVDEC support

```
cd ~/Downloads
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
mkdir build
export TARGET="${PWD}/build"
PATH="$TARGET/bin:$PATH" PKG_CONFIG_PATH="$TARGET/ffmpeg_build/lib/pkgconfig:/usr/local/lib/pkgconfig"  ./configure \
    --enable-nonfree \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --enable-gpl \
    --enable-shared \
    --disable-static \
    --enable-libx264 \
    --enable-libx265 \
    --prefix="$TARGET/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$TARGET/ffmpeg_build/include -I/usr/local/cuda-${CUDA_VERSION}/include" \
    --extra-ldflags="-L$TARGET/ffmpeg_build/lib -L/usr/local/cuda-${CUDA_VERSION}/lib64" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --bindir="$TARGET/bin" 
```

Check the following sections to make sure x264/x265 and hardware acceleration are correctly configured

```
External libraries:
alsa                    libx264                 libxcb                  lzma
iconv                   libx265                 libxcb_shm              zlib

External libraries providing hardware acceleration:
cuda                    cuda_nvcc               ffnvcodec               nvdec                   v4l2_m2m
cuda_llvm               cuvid                   libnpp                  nvenc                   vaapi
```

Compile FFMPEG

```
make -j 12
make install 
hash -r
```

Export environment variables so that opencv can find FFMPEG
```
export TARGET=$HOME/Downloads/FFmpeg/build
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TARGET/ffmpeg_build/lib/
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$TARGET/ffmpeg_build/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR:$TARGET/ffmpeg_build/lib/
```

Note: To use cv2 with this custom FFmpeg, it looks like the system must know the path to the libraries to run import cv2.
Specifying the correct LD_LIBRARY_PATH before running python does the trick

# Go to conda environment

This is important, everything has to be done in the proper conda environment 

```
conda create -n build_opencv python=3.9
conda activate build_opencv
conda install qt-main==5.15.2 # this will determine which version of qt gets used by opencv
conda install numpy
```


# Make wheels

Note: I seem to have an incompatibility issue with RAPIDS cuml due to glog/gflags
```
ERROR: flag 'logtostderr' was defined more than once (in files './src/logging.cc' and '/home/conda/feedstock_root/build_artifacts/glog_1649143692077/work/src/logging.cc').
```
Here I disable sfm, to get rid of that issue.

```
cd ~/Downloads
git clone --recursive https://github.com/opencv/opencv-python.git
cd opencv-python
git submodule update --init --recursive --remote opencv
export CMAKE_ARGS="-DWITH_CUDA=ON -DENABLE_FAST_MATH=1 -DCUDA_FAST_MATH=1 -DBUILD_opencv_sfm=OFF -DWITH_FFMPEG=ON -DWITH_GTK=OFF -DWITH_QT=ON"
export ENABLE_CONTRIB=1
export ENABLE_ROLLING=1
pip wheel . --verbose
```

Pay attention to :

```
  --   GUI:                           QT5
  --     QT:                          YES (ver 5.15.2 )
  --       QT OpenGL support:         NO

  --   NVIDIA CUDA:                   YES (ver 12.3, CUFFT CUBLAS FAST_MATH)
  --     NVIDIA GPU arch:             50 52 60 61 70 75 80 86 89 90
  --     NVIDIA PTX archs:            90

  --   Python 3:
  --     Interpreter:                 /home/martin/miniconda3/envs/build_opencv/bin/python (ver 3.9.18)
  --     Libraries:                   /home/martin/miniconda3/envs/build_opencv/lib/libpython3.9.so (ver 3.9.18)
  --     numpy:                       /tmp/pip-build-env-bsvn406k/overlay/lib/python3.9/site-packages/numpy/core/include (ver 1.19.3)
  --     install path:                python/cv2/python-3

  --   Video I/O:
  --     FFMPEG:                      YES
  --       avcodec:                   YES (60.35.100)
  --       avformat:                  YES (60.18.100)
  --       avutil:                    YES (58.33.100)
  --       swscale:                   YES (7.6.100)
  --       avresample:                NO
```

# Troubleshooting

## General advice 

- make sure that the computer you install the wheel on has the same CUDA version installed
- use in environment with the same python version that was used to build the wheel

## Specifics problems

See https://github.com/opencv/opencv-python/issues/871

```
  Exception: Not found: 'python/cv2/py.typed'
  error: subprocess-exited-with-error
  
  × Building wheel for opencv-contrib-python (pyproject.toml) did not run successfully.
  │ exit code: 1
  ╰─> See above for output.
```

There seem to be an issue with the version of the opencv submodule, manually switch to recent commit and make sure you enable ROLLING
(maybe updating git could help?)

```
cd opencv
git checkout 8b577ab
git log|grep '#24022'
cd ..
export ENABLE_ROLLING=1
pip wheel . --verbose
```

To update git (not sure if necessary)

```
sudo apt-add-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git
```

