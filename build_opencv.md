# Why would you want to compile opencv yourself ?

- extra codecs
- cuda support

# NVIDIA

* NVIDIA CUDA Toolkit

Choose the right CUDA version and compute capability for your graphics card (https://developer.nvidia.com/cuda-gpus#compute)
```
export CUDA_VERSION=12.0
export COMPUTE_CAPABILITY=6.1
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
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-${CUDA_VERSION}
```

Reboot.

check https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions

```
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
 ```

# Go to conda environment

This is important, everything has to be done in the proper conda environment 

```
conda create -n build_opencv python=3.8.10
conda activate build_opencv
pip install numpy
```

# Install dependencies

```
sudo apt install build-essential cmake pkg-config unzip yasm git checkinstall \
libjpeg-dev libpng-dev libtiff-dev \
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libxvidcore-dev x264 libx264-dev libfaac-dev libmp3lame-dev libtheora-dev \
libfaac-dev libmp3lame-dev libvorbis-dev libva-dev libx265-dev libnuma-dev \
libgtk-3-dev libtbb-dev libatlas-base-dev gfortran \
libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavresample-dev \
libopenblas-dev liblapack-dev libeigen3-dev python3-dev
```

# Download sources

Adapt to the version of opencv you want to install

```
export OPENCV_VERSION=4.8.1
```

```
cd ~/Downloads
wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip
wget -O opencv_contrib.zip  https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV_VERSION}.zip
unzip opencv.zip
unzip opencv_contrib.zip
cd opencv-${OPENCV_VERSION}
mkdir build
cd build
```

# Configure 

Modify OPENCV_EXTRA_MODULES_PATH accordingly

```
cmake -D WITH_CUDA=ON \
-D ENABLE_FAST_MATH=ON \
-D CUDA_FAST_MATH=ON \
-D WITH_CUBLAS=ON \
-D CUDA_ARCH_BIN=${COMPUTE_CAPABILITY} \
-D BUILD_TIFF=ON \
-D BUILD_opencv_java=OFF \
-D WITH_OPENGL=ON \
-D WITH_OPENCL=ON \
-D WITH_IPP=ON \
-D WITH_TBB=ON \
-D WITH_EIGEN=ON \
-D WITH_V4L=ON \
-D WITH_VTK=OFF \
-D BUILD_TESTS=OFF \
-D BUILD_PERF_TESTS=OFF \
-D CMAKE_BUILD_TYPE=RELEASE \
-D BUILD_opencv_python3=ON \
-D BUILD_opencv_python2=OFF \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
-D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
-D INSTALL_C_EXAMPLES=ON \
-D INSTALL_PYTHON_EXAMPLES=ON \
-D OPENCV_ENABLE_NONFREE=ON \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D PYTHON3_EXECUTABLE=$(which python3) \
-D PYTHON_DEFAULT_EXECUTABLE=$(which python3) \
-D OPENCV_EXTRA_MODULES_PATH=/home/martin/Downloads/opencv_contrib-${OPENCV_VERSION}/modules \
-D BUILD_EXAMPLES=ON ..
```

# Make sure configuration is correct

Look for the Python section in the output, it should look something like this

```
-- Python 3:
--  Interpreter:  /home/martin/miniconda3/envs/VirtualReality/bin/python3 (ver 3.8.16)
--  Libraries:    /home/martin/miniconda3/envs/VirtualReality/lib/libpython3.8.so (ver 3.8.16)
--  numpy:        /home/martin/miniconda3/envs/VirtualReality/lib/python3.8/site-packages/numpy/core/include (ver 1.24.2)
--  install path: /home/martin/miniconda3/envs/VirtualReality/lib/python3.8/site-packages/cv2/python-3.8


--   NVIDIA CUDA:                   YES (ver 12.0, CUFFT CUBLAS FAST_MATH)
--     NVIDIA GPU arch:             61
--     NVIDIA PTX archs:

```

# Compile and install

```
make -j4
sudo make install
sudo ldconfig
```

# Troubleshooting

```
ImportError: /home/martin/miniconda3/envs/VirtualReality/bin/../lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /usr/local/lib/libopencv_gapi.so.407)
> conda install -c conda-forge gcc=12.1.0
```

```
ImportError: /lib/x86_64-linux-gnu/libp11-kit.so.0: undefined symbol: ffi_type_pointer, version LIBFFI_BASE_7.0
> conda install python=3.8.10
```
