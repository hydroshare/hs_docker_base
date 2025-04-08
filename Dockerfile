FROM python:3.12.9-bullseye

ENV DEBIAN_FRONTEND noninteractive
ENV PY_SAX_PARSER hs_core.xmlparser

RUN printf "deb http://deb.debian.org/debian/ bullseye main\ndeb http://deb.debian.org/debian/ bullseye-updates main\ndeb http://security.debian.org/debian-security bullseye-security main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    lsb-release \
    sudo

# additionall packages for building gdal
RUN apt-get update && apt-get install -y g++ sqlite3 libsqlite3-dev libtiff5-dev pkg-config

RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

COPY docker.list /etc/apt/sources.list.d/
RUN sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

RUN apt-get update && apt-get install -y \
    postgresql-14 \
    postgresql-client-14
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
    apt-utils \
    libfuse2 \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    binutils \
    build-essential \
    git \
    netcdf-bin

# install node
# https://github.com/nodesource/distributions/blob/master/README.md
RUN curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh \
    && chmod +x nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get install -y nodejs

RUN npm install -g phantomjs-prebuilt

# RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
#     gdal-bin \
#     libgdal-dev \
#     python3-gdal

# install cmake
RUN apt-get update && apt-get install -y cmake

WORKDIR /

# Install pip based packages (due to dependencies some packages need to come first)
RUN pip install --upgrade pip 
RUN pip install 'setuptools<58.0.0'
RUN pip install setuptools-scm==5.0.2
RUN pip install numpy==1.26.4
COPY ./requirements.txt /requirements.txt
RUN pip install -r requirements.txt

# Install pandas late -- incompatibility between pandas and python-dateutil versions
RUN pip install pandas==2.2.2

# now upgrade setuptools
RUN pip install --upgrade setuptools

# Set environment variables for GDAL
ENV CPLUS_INCLUDE_PATH /usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

RUN apt-get update && apt-get install -y proj-bin

# Download GDAL v3.10.3 Source
WORKDIR /
RUN wget download.osgeo.org/gdal/CURRENT/gdal3103.zip

# check the checksum
RUN wget download.osgeo.org/gdal/CURRENT/gdal3103.zip.md5
RUN md5sum -c gdal3103.zip.md5
# Unzip GDAL Source
RUN unzip gdal3103.zip
# Install GDAL
RUN cd gdal-3.10.3 \
    && mkdir build \
    && cd build \
    && cmake ..
# RUN cd gdal-3.10.3/build \
#     && make -j 4 \
#     && make install \
#     && ldconfig
# Set GDAL_DATA environment variable
ENV GDAL_DATA /usr/local/share/gdal
# Set PATH so that recompiled GDAL is used
ENV PATH /usr/local/bin:$PATH
# Set PKG_CONFIG_PATH so that recompiled GDAL is used
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
# Set CPLUS_INCLUDE_PATH so that recompiled GDAL is used
ENV CPLUS_INCLUDE_PATH /usr/local/include/gdal
# Set C_INCLUDE_PATH so that recompiled GDAL is used
ENV C_INCLUDE_PATH /usr/local/include/gdal

# Set LD_LIBRARY_PATH so that recompiled GDAL is used
ENV LD_LIBRARY_PATH /usr/local/lib

# install gdal python bindings
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
    libgdal-dev \
    python3-gdal
RUN pip install gdal[numpy]==3.10.3

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Explicitly set user/group IDs for hydroshare service account
RUN groupadd --system storage-hydro --gid=10000 \
    && useradd --system -g storage-hydro --uid=10000 --shell /bin/bash --home /hydroshare hydro-service
RUN echo 'hydro-service:docker' | chpasswd
ENV DEBIAN_FRONTEND teletype

# set UTF-8 env locale
RUN echo UTF-8/en_US.UTF-8 UTF-8 > /etc/local.gen; locale-gen
# Cleanup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
