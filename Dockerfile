FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04 
LABEL desc="Configure jupyter lab with GPU support"

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget git cmake

# install anaconda with python 3.6
RUN wget https://repo.continuum.io/archive/Anaconda3-5.2.0-Linux-x86_64.sh -O anaconda.sh -q && \
	chmod +x anaconda.sh && \
	./anaconda.sh -b -p /usr/local/anaconda && \
	rm anaconda.sh
ENV PATH /usr/local/anaconda/bin:$PATH
RUN conda update conda && \
    conda update anaconda --all

# install TensorFlow
RUN conda install tensorflow-gpu

# install PyTorch
RUN conda install pytorch torchvision -c pytorch

# install XGBoost
RUN pip install xgboost

# install OpenCV
ENV OPENCV_VERSION=4.0.1
RUN apt install build-essential unzip pkg-config -y && \
    apt install libjpeg-dev libpng-dev libtiff-dev -y && \
    apt install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev -y && \
    apt install libatlas-base-dev gfortran -y
RUN mkdir opencv && cd opencv && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm -rf ${OPENCV_VERSION}.zip && \
    cd opencv-${OPENCV_VERSION}
RUN mkdir -p opencv/opencv-${OPENCV_VERSION}/build && \
    cd opencv/opencv-${OPENCV_VERSION}/build && \
    cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_FFMPEG=NO \
    -D WITH_IPP=NO \
    -D WITH_OPENEXR=NO \
    -D WITH_TBB=YES \
    -D BUILD_EXAMPLES=NO \
    -D BUILD_ANDROID_EXAMPLES=NO \
    -D INSTALL_PYTHON_EXAMPLES=NO \
    -D BUILD_DOCS=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=ON \
    -D PYTHON3_EXECUTABLE=/usr/local/anaconda/bin/python \
    -D PYTHON3_INCLUDE_DIR=/usr/local/anaconda/include/python3.6m/ \
    -D PYTHON3_LIBRARY=/usr/local/anaconda/lib/libpython3.6m.so \
    -D PYTHON_LIBRARY=/usr/local/anaconda/lib/libpython3.6m.so \
    -D PYTHON3_PACKAGES_PATH=/usr/local/anaconda/lib/python3.6/site-packages/ \
    -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/anaconda/lib/python3.6/site-packages/numpy/core/include/ \
    .. && \
    make -j10 && \
    make install && \
    cd && rm -rf opencv

# install CatBoost (currently without GPU)
RUN pip install catboost

# install LGBM
RUN apt install ocl-icd-libopencl1 ocl-icd-opencl-dev libboost-dev libboost-system-dev libboost-filesystem-dev -y
RUN pip install lightgbm --install-option=--gpu

# install additional packages and enable extenssions
RUN pip install tqdm plotly ipywidgets hyperopt && \
    jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    conda install -c conda-forge nodejs && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install @jupyterlab/plotly-extension

# Prepare and start JupyterLab
# Using docs: https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#docker-cmd
RUN mkdir working_dir
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 8888
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--notebook-dir=/working_dir"]
