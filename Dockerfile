FROM python:2.7.11
MAINTAINER Michael J. Stealey <stealey@renci.org>

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
COPY docker.list /etc/apt/sources.list.d/

RUN apt-get update && apt-get install -y \
    docker-engine \
    sudo \
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
    netcdf-bin

# export statements
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal \
    && export C_INCLUDE_PATH=/usr/include/gdal \
    && export GEOS_CONFIG=/usr/bin/geos-config

# Install SSH for remote PyCharm debugging
RUN mkdir /var/run/sshd
RUN echo 'root:docker' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Add docker user for use with SSH debugging
RUN useradd -d /home/docker -g docker docker \
    && echo 'docker:docker' | chpasswd

WORKDIR /usr/src/

# Install iRODS 4.1.5 packages
RUN curl ftp://ftp.renci.org/pub/irods/releases/4.1.8/ubuntu14/irods-runtime-4.1.8-ubuntu14-x86_64.deb -o irods-runtime.deb \
    && curl ftp://ftp.renci.org/pub/irods/releases/4.1.8/ubuntu14/irods-icommands-4.1.8-ubuntu14-x86_64.deb -o irods-icommands.deb \
    && sudo dpkg -i irods-runtime.deb irods-icommands.deb \
    && sudo apt-get -f install \
    && rm irods-runtime.deb irods-icommands.deb

# Install pip based packages (due to dependencies some packages need to come first)
RUN pip install --upgrade pip
RUN pip install Django==1.8.12
RUN pip install --no-deps Mezzanine==4.1.0
RUN pip install numpy==1.10.4
RUN pip install GDAL==1.10.0 --global-option=build_ext --global-option="-I/usr/include/gdal"
RUN pip install \
    arrow==0.7.0 \
    autoflake==0.6.6 \
    autopep8==1.2.2 \
    bagit==1.5.4 \
    beautifulsoup4==4.4.1 \
    bleach==1.4.2 \
    celery==3.1.23 \
    chardet==2.3.0 \
    coverage==4.0.3 \
    django-autocomplete-light==2.0.9 \
    django-compressor==2.0 \
    django-contrib-comments==1.6.2 \
    django-cors-headers==1.1.0 \
    django-crispy-forms==1.6.0 \
    django-debug-toolbar==1.4 \
    django-haystack==2.4.1 \
    django-inplaceedit==1.4.1 \
    django-jsonfield==0.9.19 \
    django-modeltranslation==0.11 \
    django-nose==1.4.3 \
    django-oauth-toolkit==0.10.0 \
    django-timedeltafield==0.7.10 \
    django-widget-tweaks==1.4.1 \
    djangorestframework==3.3.3 \
    docker-py==1.7.2 \
    filebrowser-safe==0.4.3 \
    flake8==2.5.4 \
    future==0.15.2 \
    geojson==1.3.2 \
    google.foresite-toolkit==1.3 \
    grappelli-safe==0.4.2 \
    gunicorn==19.4.5 \
    lxml==3.6.0 \
    mapnik==0.1 \
    matplotlib==1.5.1 \
    mock==1.3.0 \
    oauthlib==1.0.3 \
    OWSLib==0.10.3 \
    pandas==0.18.0 \
    paramiko==1.16.0 \
    pep8==1.7.0 \
    Pillow==3.1.1 \
    psycopg2==2.6.1 \
    pyflakes==1.1.0 \
    pylint==1.5.5 \
    pyproj==1.9.5.1 \
    pysolr==3.4.0 \
    pysqlite==2.8.1 \
    -e git+https://github.com/iPlantCollaborativeOpenSource/python-irodsclient.git@dcd234c166c06bdfc40fa2ef135c2511e0a4e7ac#egg=python_irodsclient \
    pytz==2016.3 \
    redis==2.10.5 \
    requests==2.9.1 \
    requests-oauthlib==0.6.1 \
    sh==1.11 \
    Shapely==1.5.13 \
    suds-jurko==0.6 \
    tzlocal==1.2.2

RUN USE_SETUPCFG=0 \
    HDF5_INCDIR=/usr/include/hdf5/serial \
    pip install netCDF4==1.2.4

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
