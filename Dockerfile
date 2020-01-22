FROM python:3.6-jessie
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV DEBIAN_FRONTEND noninteractive
ENV PY_SAX_PARSER=hs_core.xmlparser

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    sudo \
    && apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    
RUN curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -

# Add docker.list and requirements.txt - using /tmp to keep hub.docker happy
COPY . /tmp
RUN cp /tmp/docker.list /etc/apt/sources.list.d/ \
    && cp /tmp/requirements.txt /requirements.txt

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
    && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
    apt-utils \
    docker-engine \
    libfuse2 \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    binutils \
    libproj-dev \
    gdal-bin \
    build-essential \
    libgdal-dev \
    libgdal1h \
    postgresql-9.4 \
    postgresql-client-9.4 \
    git \
    rsync \
    openssh-client \
    openssh-server \
    netcdf-bin \
    supervisor \
    nodejs
RUN npm install -g phantomjs-prebuilt

WORKDIR /

#install numpy before matplotlib
RUN pip install 'numpy==1.16.0'
RUN pip install git+https://github.com/sblack-usu/defusedexpat.git

# Install pip based packages (due to dependencies some packages need to come first)
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal 
RUN export C_INCLUDE_PATH=/usr/include/gdal 
RUN export GEOS_CONFIG=/usr/bin/geos-config 
RUN HDF5_INCDIR=/usr/include/hdf5/serial 
RUN pip install --upgrade pip 
RUN pip install -r requirements.txt

# Install GDAL 2.4.1 from source
RUN wget http://download.osgeo.org/gdal/2.4.1/gdal-2.4.1.tar.gz \
    && tar -xzf gdal-2.4.1.tar.gz \
    && rm gdal-2.4.1.tar.gz

WORKDIR /gdal-2.4.1
RUN ./configure --with-python --with-geos=yes \
    && make \
    && sudo make install \
    && sudo ldconfig
WORKDIR /

# Install iRODS v.4.2.6
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ trusty main" | \
    sudo tee /etc/apt/sources.list.d/renci-irods.list \
    && sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    irods-runtime \
    irods-icommands

# inplaceedit in pip doesn't seem compatible with Django 1.11 yet...
RUN pip install git+https://github.com/theromis/django-inplaceedit.git@e6fa12355defedf769a5f06edc8fc079a6e982ec
# foresite-toolkit in pip isn't compatible with python3
RUN pip install git+https://github.com/sblack-usu/foresite-toolkit.git#subdirectory=foresite-python/trunk

# Install SSH for remote PyCharm debugging
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

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
