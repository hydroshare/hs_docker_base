FROM python:2.7.11
MAINTAINER Michael J. Stealey <stealey@renci.org>

COPY requirements.txt /tmp/
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
COPY docker.list /etc/apt/sources.list.d/

RUN apt-get update && apt-get install -y \
    docker-engine \
    sudo \
    libfuse2 \
    python-mapnik \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    python-imaging \
    binutils \
    libproj-dev \
    gdal-bin \
    build-essential \
    libgdal-dev \
    libgdal1h \
    python-gdal \
    postgresql \
    postgresql-client

RUN pip install --upgrade pip
RUN pip install Django==1.8.11
RUN pip install --no-deps Mezzanine==4.1.0
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal \
    && export C_INCLUDE_PATH=/usr/include/gdal
#RUN pip install --requirement /tmp/requirements.txt

WORKDIR /usr/src/

# Install iRODS 4.1.5 packages
RUN curl ftp://ftp.renci.org/pub/irods/releases/4.1.5/ubuntu14/irods-runtime-4.1.5-ubuntu14-x86_64.deb -o irods-runtime.deb \
    && curl ftp://ftp.renci.org/pub/irods/releases/4.1.5/ubuntu14/irods-icommands-4.1.5-ubuntu14-x86_64.deb -o irods-icommands.deb \
    && sudo dpkg -i irods-runtime.deb irods-icommands.deb \
    && sudo apt-get -f install \
    && rm irods-runtime.deb irods-icommands.deb

RUN pip install \
    numpy

RUN pip install \
    pysqlite \
    django-contrib-comments \
    Pillow \
    grappelli_safe \
    filebrowser_safe \
    bleach \
    beautifulsoup4 \
    pytz \
    tzlocal \
    chardet \
    django-modeltranslation \
    django-compressor \
    requests \
    requests_oauthlib \
    pyflakes \
    pep8 \
    celery redis \
    django-autocomplete-light==2.0.9 \
    django-oauth-toolkit \
    oauthlib \
    django-cors-headers \
    django-inplaceedit \
    django-nose \
    future \
    django-crispy-forms \
    django-haystack \
    djangorestframework \
    django-widget-tweaks \
    psycopg2 \
    sh \
    django-timedeltafield \
    arrow \
    lxml \
    requests\
    google.foresite-toolkit \
    bagit \
    django-jsonfield \
    netCDF4 \
    pyproj \
    pysolr \
    mapnik \
    docker-py \
    pandas \
    Shapely \
    matplotlib \
    geojson \
    paramiko

RUN pip install \
    GDAL==1.10.0 --global-option=build_ext --global-option="-I/usr/include/gdal"

RUN pip install \
    suds-jurko \
    OWSLib \
    -e git+https://github.com/iPlantCollaborativeOpenSource/python-irodsclient.git@dcd234c166c06bdfc40fa2ef135c2511e0a4e7ac#egg=python_irodsclient

RUN pip install \
    mock

## Install base packages and pre-reqs for HydroShare
#USER root
#RUN apt-get update && apt-get install -y \
#    python2.7-mapnik python2.7-scipy python2.7-numpy python2.7-psycopg2 cython python2.7-pysqlite2 \
#    nodejs npm python-virtualenv \
#    postgresql-9.3 postgresql-client-common postgresql-common postgresql-client-9.3 redis-tools \
#    sqlite3 sqlite3-pcre libspatialite-dev libspatialite5 spatialite-bin \
#    ssh git libfreetype6 libfreetype6-dev libxml2-dev libxslt-dev libprotobuf-dev \
#    python2.7-gdal gdal-bin libgdal-dev gdal-contrib python-pillow protobuf-compiler \
#    libtokyocabinet-dev tokyocabinet-bin libreadline-dev ncurses-dev \
#    docker.io curl libssl0.9.8 libfuse2 fuse \
#    nco netcdf-bin
#
## Add docker user
#RUN useradd -m docker -g docker
#RUN echo docker:docker | chpasswd
#
## Build add-ons and pip install requirements.txt
#ADD . /home/docker
#WORKDIR /home/docker/pysqlite-2.6.3/
#RUN python setup.py install
#WORKDIR /home/docker
#RUN pip install numexpr==2.4
#RUN wget https://bootstrap.pypa.io/get-pip.py
#RUN python get-pip.py
#RUN pip install -U distribute
#RUN pip install -r requirements.txt
#RUN npm install carto
#
## Configure FUSE to allow other user
#RUN echo "user_allow_other" > /etc/fuse.conf

## Install netcdf4 python
#RUN curl -O https://pypi.python.org/packages/source/n/netCDF4/netCDF4-1.1.1.tar.gz
#RUN tar -xvzf netCDF4-1.1.1.tar.gz
#WORKDIR /home/docker/netCDF4-1.1.1
#RUN python setup.py install
#WORKDIR /home/docker
#RUN rm netCDF4-1.1.1.tar.gz
#
## Add the hydroshare directory
#ADD . /home/docker/hydroshare
#RUN chown -R docker:docker /home/docker
#WORKDIR /home/docker/hydroshare
#
## Configure and Cleanup
#RUN rm -rf /tmp/pip-build-root
#RUN mkdir -p /var/run/sshd
#RUN echo root:docker | chpasswd
#RUN sed "s/without-password/yes/g" /etc/ssh/sshd_config > /etc/ssh/sshd_config2
#RUN sed "s/UsePAM yes/UsePAM no/g" /etc/ssh/sshd_config2 > /etc/ssh/sshd_config
#RUN mkdir -p /home/docker/hydroshare/static/media/.cache
#RUN chown -R docker:docker /home/docker
#RUN mkdir -p /tmp
#RUN chmod 777 /tmp
