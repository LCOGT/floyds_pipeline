FROM python:2.7.16-slim-buster

ENV iraf /iraf/iraf/
ENV IRAFARCH linux64
ENV TERM xterm

RUN apt-get --allow-releaseinfo-change update \
        && apt -y install gcc make flex git gfortran \
        && apt -y install libcurl4-openssl-dev libexpat-dev libreadline-dev gettext \
        && apt-get autoclean \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $iraf \
        && cd /iraf \
        && git clone https://github.com/iraf-community/iraf.git \
        && cd $iraf \
        && git checkout ba22d13 \
        && ./install < /dev/null \
        && make $IRAFARCH \
        && make sysgen

RUN apt-get update && \
        apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev

RUN apt-get update \
        && apt-get -y install libx11-dev libcfitsio-bin wget x11-apps libtk8.6 libjpeg-dev \
        openssh-client wcstools libxml2 vim zip \
        && apt-get autoclean \
        && rm -rf /var/lib/apt/lists/*

RUN pip install setuptools==44.1.1
RUN pip install numpy==1.16.6 astropy==2.0.16 pyraf==2.1.15 matplotlib==2.2.4 xhtml2pdf==0.2.4 pathlib2==2.3.5 requests==2.22.0 pytest==3.6.4 stsci.tools==3.6.0 && rm -rf ~/.cache/pip

RUN wget https://www.python.org/ftp/python/3.9.12/Python-3.9.12.tgz && \
        tar xvf Python-3.9.12.tgz && cd Python-3.9.12 && \
        ./configure --enable-optimizations --with-ensurepip=install && \
        make -j 12 && make altinstall

RUN python3.9 -m pip install ocs_ingester>=3.0.3 kombu && rm -rf ~/.cache/pip

RUN apt-get --allow-releaseinfo-change update && \
        apt-get install -y libxml2-dev libxslt-dev tclsh libxmlrpc-c++8-dev autoconf && \ 
        git clone https://github.com/SAOImageDS9/SAOImageDS9 && \
        cd SAOImageDS9 && \
        git checkout v8.6 && \
        unix/configure && \
        cd openssl && \
        ./config && \
        make build_crypto && \
        make build_engines && \
        make && \
        cd .. && \
        make && \
        ln -s /SAOImageDS9/bin/ds9 /usr/bin/ && \
        apt-get autoclean && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/archive/iraf && /usr/sbin/groupadd -g 10000 "domainusers" \
        && /usr/sbin/useradd -g 10000 -d /home/archive -M -N -u 10087 archive \
        && chown -R archive:domainusers /home/archive \
        && mkdir -p /archive/engineering \
        && chown -R archive:domainusers /archive/engineering

USER archive

WORKDIR /home/archive/iraf

RUN mkiraf --term=xgterm -i

USER root

COPY . /usr/src/floyds_pipeline

WORKDIR /usr/src/floyds_pipeline

RUN python setup.py install

USER archive

WORKDIR /home/archive

ENV DISPLAY host.docker.internal:0
