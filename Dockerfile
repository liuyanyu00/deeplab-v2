FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
LABEL maintainer caffe-maint@googlegroups.com

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-setuptools \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# MATIO
RUN wget http://jaist.dl.sourceforge.net/project/matio/matio/1.5.2/matio-1.5.2.tar.gz && \
    tar -xvzf matio-1.5.2.tar.gz && \
    rm matio-1.5.2.tar.gz
    
WORKDIR /opt/matio-1.5.2

RUN ./configure && make -j8 && make install -j8

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

ENV INCLUDE_DIRS=/opt/matio-1.5.2/src/:$INCLUDE_DIRS
ENV LIBRARY_DIRS=/opt/matio-1.5.2/src/:$LIBRARY_DIRS

# FIXME: use ARG instead of ENV once DockerHub supports this
# https://github.com/docker/hub-feedback/issues/460
ENV CLONE_TAG=master

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/liuyanyu00/deeplab-v2.git .
RUN python -m pip install -U pip && pip install --upgrade pip 
RUN cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. 
RUN mkdir build && cd build && \
    cmake -DUSE_CUDNN=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

WORKDIR /workspace
