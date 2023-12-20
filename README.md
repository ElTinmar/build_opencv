# Install wheel in a conda environment

```
conda create -n test python=3.8
conda activate test
pip install https://github.com/ElTinmar/build_opencv/raw/main/opencv_contrib_python_rolling-4.8.0.20231210-cp38-cp38-linux_x86_64.whl
```

# Test the installation 

```
import cv2
print(cv2.__version__)
cv2.cuda.getDevice()
```
