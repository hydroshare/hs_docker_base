FROM python:3.6-bullseye

ENV DEBIAN_FRONTEND noninteractive
ENV PY_SAX_PARSER=hs_core.xmlparser

RUN printf "deb http://deb.debian.org/debian/ bullseye main\ndeb http://security.debian.org/debian-security bullseye-security main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    sudo \
    && apt-key adv --keyserver keys.openpgp.org --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

RUN curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

COPY docker.list /etc/apt/sources.list.d/
RUN sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
    && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
    apt-utils \
    docker-ce \
    libfuse2 \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    binutils \
    libproj-dev \
    gdal-bin \
    build-essential \
    libgdal-dev \
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

# Add docker.list and requirements.txt - using /tmp to keep hub.docker happy
COPY . /tmp
RUN cp /tmp/requirements.txt /requirements.txt
WORKDIR /

#install numpy before matplotlib
RUN pip install 'numpy==1.16.*'

# This is the only thing holding us back from python 3.9
RUN pip install git+https://github.com/sblack-usu/defusedexpat.git

# Install pip based packages (due to dependencies some packages need to come first)
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal 
RUN export C_INCLUDE_PATH=/usr/include/gdal 
RUN export GEOS_CONFIG=/usr/bin/geos-config 
RUN HDF5_INCDIR=/usr/include/hdf5/serial 
RUN pip install --upgrade pip 
RUN pip install -r requirements.txt

# foresite-toolkit in pip isn't compatible with python3
RUN pip install git+https://github.com/sblack-usu/foresite-toolkit.git#subdirectory=foresite-python/trunk


# ########################################################
# TODO: not sure that we need to wget gdal and install here? Removing for now...
# We install gdal-bin above with apt... but maybe we need to do this to get geos? If so, maybe we should remove it above...
# RUN wget https://ftp.osuosl.org/pub/osgeo/download/gdal/3.5.2/gdal-3.5.2.tar.gz \
#     && tar -xzf gdal-3.5.2.tar.gz \
#     && rm gdal-3.5.2.tar.gz

# WORKDIR /gdal-3.5.2
# RUN ./configure --with-python --with-geos=yes \
#     && make \
#     && sudo make install \
#     && sudo ldconfig
# WORKDIR /

# TODO: do we need to add Python bindings for Gdal?
# https://mothergeo-py.readthedocs.io/en/latest/development/how-to/gdal-ubuntu-pkg.html
# RUN python -m pip install --upgrade --no-cache-dir setuptools==58.0.2
# RUN pip install GDAL==`ogrinfo --version`
# ########################################################



# Install iRODS
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ bullseye main" | \
    sudo tee /etc/apt/sources.list.d/renci-irods.list \
    && sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    irods-runtime \
    irods-icommands

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
