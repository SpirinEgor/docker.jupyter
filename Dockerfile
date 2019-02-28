FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04 
LABEL desc="Configure jupyter lab with GPU support"

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget git 

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
RUN pip install https://download.pytorch.org/whl/cu100/torch-1.0.1.post2-cp37-cp37m-linux_x86_64.whl && \
    pip install torchvision

# Prepare and start JupyterLab
# Using docs: https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#docker-cmd
RUN mkdir working_dir
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 8888
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--notebook-dir=/working_dir"]

