FROM ubuntu:16.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda
RUN curl -so ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH

# Create a Python 3.6 environment
RUN /home/user/miniconda/bin/conda install conda-build \
 && /home/user/miniconda/bin/conda create -y --name py36 python=3.6.4 \
 && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py36
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH

# Ensure conda version is at least 4.4.11
# (because of this issue: https://github.com/conda/conda/issues/6811)
ENV CONDA_AUTO_UPDATE_CONDA=false
RUN conda install -y "conda>=4.4.11" && conda clean -ya

# No CUDA-specific steps
ENV NO_CUDA=1

# Install PyTorch and Torchvision
RUN conda install -y -c pytorch \
    pytorch-nightly \
 && conda clean -ya
 
# Install Pyro dependencies
RUN conda install -y \
    contextlib2 \
    graphviz \
    networkx \
    six \
    flake8 \
    isort \
    nbformat \
    pypandoc \
    pytest \
    pytest-xdist \
    scipy \
    sphinx \
    sphinx_rtd_theme \
 && conda clean -ya
 
RUN pip install --upgrade pip 
 
RUN pip install \
    nbstripout \
    nbval \
    yapf

RUN pip install git+git://github.com/uber/pyro.git

RUN conda install jupyter matplotlib seaborn

# Set the default command to python3
# CMD ["python3"]

CMD jupyter notebook --notebook-dir='/app' --ip="*" --no-browser --allow-root

# docker run -it --rm --init -v $PWD:/app/compiled-inference -p 127.0.0.1:8888:8888 torch
