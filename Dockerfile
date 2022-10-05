# FROM hydroshare/hs_docker_base:release-1.13
# https://github.com/hydroshare/hs_docker_base/blob/develop/Dockerfile
# MAINTAINER Phuong Doan pdoan@cuahsi.org
FROM python:3 as hs_docker_base
MAINTAINER Michael J. Stealey <stealey@renci.org>


ENV DEBIAN_FRONTEND noninteractive
ENV PY_SAX_PARSER=hs_core.xmlparser

RUN printf "deb http://deb.debian.org/debian/ bullseye main\ndeb http://security.debian.org/debian-security bullseye-security main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    sudo \
    && apt-key adv --keyserver keys.openpgp.org --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    # apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

RUN curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Add docker.list and requirements.txt - using /tmp to keep hub.docker happy
COPY . /tmp
RUN cp /tmp/docker.list /etc/apt/sources.list.d/ \
    && cp /tmp/requirements.txt /requirements.txt

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
    # libgdal1h \
    # TODO should we include geos ?
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
# RUN pip install 'numpy==1.16.0'

# TODO: need to figure out how to get defusedexpat...
# RUN pip install git+https://github.com/sblack-usu/defusedexpat.git

# Install pip based packages (due to dependencies some packages need to come first)
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal 
RUN export C_INCLUDE_PATH=/usr/include/gdal 
RUN export GEOS_CONFIG=/usr/bin/geos-config 
RUN HDF5_INCDIR=/usr/include/hdf5/serial 
RUN pip install --upgrade pip 
RUN pip install -r requirements.txt

# TODO: not sure that we need this?
# Install GDAL 3.5.2 from source
# RUN wget http://download.osgeo.org/gdal/3.5.2/gdal-3.5.2.tar.gz \
RUN wget https://ftp.osuosl.org/pub/osgeo/download/gdal/3.5.2/gdal-3.5.2.tar.gz \
    && tar -xzf gdal-3.5.2.tar.gz \
    && rm gdal-3.5.2.tar.gz

WORKDIR /gdal-3.5.2
RUN ./configure --with-python --with-geos=yes \
    && make \
    && sudo make install \
    && sudo ldconfig
WORKDIR /

# TODO: do we need to add Python bindings for Gdal?
# https://mothergeo-py.readthedocs.io/en/latest/development/how-to/gdal-ubuntu-pkg.html
# RUN python -m pip install --upgrade --no-cache-dir setuptools==58.0.2
# RUN pip install GDAL==3.2.2
# RUN pip install GDAL==`ogrinfo --version`

# Install iRODS
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ bullseye main" | \
    sudo tee /etc/apt/sources.list.d/renci-irods.list \
    && sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    irods-runtime \
    irods-icommands

# TODO: move this to requirements.txt not sure that we actually need it...
# inplaceedit in pip doesn't seem compatible with Django 1.11 yet...
RUN pip install git+https://github.com/theromis/django-inplaceedit.git@e6fa12355defedf769a5f06edc8fc079a6e982ec

# TODO: not sure if we actually need this?
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

# Set the locale. TODO - remove once we have a better alternative worked out
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# Most of these are from Pabitra...
# https://github.com/hydroshare/hydroshare/compare/4738-django-3_2#diff-dd2c0eb6ea5cfc6c4bd4eac30934e2d5746747af48fef6da689e85b752f39557
# commented = devin added to requirements.txt
# RUN pip uninstall -y enum34 #devin removed from requirements
# RUN pip install deepdiff==1.7.0
# RUN pip install pytest-cov==3.0.0
# RUN pip install --upgrade rdflib==5.0.0
# RUN pip install -e git+https://github.com/hydroshare/hsmodels.git@0.5.3#egg=hsmodels
# RUN pip install six==1.16.0
# RUN pip install sorl-thumbnail==12.8.0
# RUN pip install --upgrade Django==3.2.15
# RUN pip install --upgrade Mezzanine==5.1.4
# RUN pip install --upgrade requests==2.27.1
# RUN pip install --upgrade django-security==0.12.0
# RUN pip install --upgrade django-braces==1.15.0 django-compressor==4.1 django-appconf==1.0.5 django-contrib-comments==2.2.0 django-cors-headers==3.10.1 django-crispy-forms==1.13.0 django-debug-toolbar==3.2.4 django-jsonfield==1.4.1 django-oauth-toolkit==2.1.0 django-robots==4.0
# RUN pip install --upgrade django-autocomplete-light==2.3.6
# RUN pip install --upgrade django-haystack==3.1.1
# RUN pip install --upgrade djangorestframework==3.13.1
# RUN pip install --upgrade drf-haystack==1.8.11
# RUN pip install --upgrade drf-yasg==1.20.0

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

USER root
WORKDIR /hydroshare

CMD ["/bin/bash"]
