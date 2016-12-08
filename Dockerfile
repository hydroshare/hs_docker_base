FROM python:2.7.12
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV DEBIAN_FRONTEND noninteractive
ENV PY_SAX_PARSER=hs_core.xmlparser
ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
COPY docker.list /etc/apt/sources.list.d/

RUN apt-get update && apt-get install --fix-missing -y \
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
    python-gdal \
    git \
    rsync \
    openssh-client \
    openssh-server \
    netcdf-bin \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# export statements
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal \
    && export C_INCLUDE_PATH=/usr/include/gdal \
    && export GEOS_CONFIG=/usr/bin/geos-config

WORKDIR /usr/src/

# Install iRODS 4.1.8 packages
RUN curl ftp://ftp.renci.org/pub/irods/releases/4.1.8/ubuntu14/irods-runtime-4.1.8-ubuntu14-x86_64.deb -o irods-runtime.deb \
    && curl ftp://ftp.renci.org/pub/irods/releases/4.1.8/ubuntu14/irods-icommands-4.1.8-ubuntu14-x86_64.deb -o irods-icommands.deb \
    && sudo dpkg -i irods-runtime.deb irods-icommands.deb \
    && sudo apt-get -f install \
    && rm irods-runtime.deb irods-icommands.deb

# Install GDAL 2.1.2 from source
RUN curl http://download.osgeo.org/gdal/2.1.2/gdal-2.1.2.tar.gz -o /usr/src/gdal-2.1.2.tar.gz \
    && tar -xzf gdal-2.1.2.tar.gz \
    && rm gdal-2.1.2.tar.gz

WORKDIR /usr/src/gdal-2.1.2
RUN ./configure --with-python --with-geos=yes \
    && make \
    && sudo make install \
    && sudo ldconfig

# Install pip based packages (due to dependencies some packages need to come first)
RUN pip install --upgrade pip \
    && USE_SETUPCFG=0 \
    HDF5_INCDIR=/usr/include/hdf5/serial \
    pip install netCDF4==1.2.5

RUN pip install --upgrade pip && pip install \
    amqp==2.1.3 \
    anyjson==0.3.3 \
    arrow==0.10.0 \
    astroid==1.4.8 \
    autoflake==0.6.6 \
    autopep8==1.2.4 \
    bagit==1.5.4 \
    beautifulsoup4==4.5.1 \
    billiard==3.5.0.2 \
    bleach==1.5.0 \
    celery==4.0.0 \
    chardet==2.3.0 \
    colorama==0.3.7 \
    coverage==4.2 \
    cycler==0.10.0 \
    defusedexpat==0.4 \
    defusedxml==0.4.1 \
    Django==1.8.16 \
    django-appconf==1.0.2 \
    django-autocomplete-light==2.0.9 \
    django-braces==1.10.0 \
    django-compressor==2.1 \
    django-contrib-comments==1.7.3 \
    django-cors-headers==1.3.1 \
    django-crispy-forms==1.6.1 \
    django-debug-toolbar==1.6 \
    django-haystack==2.5.1 \
    django-heartbeat==2.0.2 \
    django-inplaceedit==1.4.1 \
    django-jsonfield==1.0.1 \
    django-modeltranslation==0.12 \
    django-nose==1.4.4 \
    django-oauth-toolkit==0.11.0 \
    django-timedeltafield==0.7.10 \
    django-widget-tweaks==1.4.1 \
    djangorestframework==3.5.3 \
    docker-py==1.10.6 \
    ecdsa==0.13 \
    filebrowser-safe==0.4.6 \
    flake8==3.2.1 \
    funcsigs==1.0.2 \
    future==0.16.0 \
    geojson==1.3.3 \
    gevent==1.1.2 \
    google.foresite-toolkit==1.3 \
    grappelli-safe==0.4.5 \
    greenlet==0.4.10 \
    gunicorn==19.6.0 \
    html5lib==0.9999999 \
    isodate==0.5.4 \
    keepalive==0.5 \
    kombu==4.0.1 \
    lazy-object-proxy==1.2.2 \
    lxml==3.6.4 \
    mapnik==0.1 \
    matplotlib==1.5.3 \
    mccabe==0.5.2 \
    Mezzanine==4.1.0 \
    mock==2.0.0 \
    nose==1.3.7 \
    numpy==1.11.2 \
    oauthlib==2.0.1 \
    OWSLib==0.13.0 \
    pandas==0.19.1 \
    paramiko==2.0.2 \
    pbr==1.10.0 \
    pep8==1.7.0 \
    Pillow==3.4.2 \
    prettytable==0.7.2 \
    psutil==5.0.0 \
    psycopg2==2.6.2 \
    py2-ipaddress==3.4.1 \
    PyCRS==0.1.3 \
    pycrypto==2.6.1 \
    pyflakes==1.3.0 \
    pylint==1.6.4 \
    pyparsing==2.1.10 \
    pyproj==1.9.5.1 \
    pysolr==3.6.0 \
    pysqlite==2.8.3 \
    python-dateutil==2.6.0 \
    pytz==2016.10 \
    rcssmin==1.0.6 \
    rdflib==4.2.1 \
    redis==2.10.5 \
    requests==2.12.3 \
    requests-oauthlib==0.7.0 \
    rjsmin==1.0.12 \
    selenium==3.0.2 \
    setuptools==30.3.0 \
    sh==1.12.7 \
    Shapely==1.5.17 \
    six==1.10.0 \
    SPARQLWrapper==1.8.0 \
    sqlparse==0.2.2 \
    suds-jurko==0.6 \
    tzlocal==1.3 \
    virtualenv==15.1.0 \
    websocket-client==0.39.0 \
    wrapt==1.10.8 \
    xmltodict==0.10.2

RUN pip install --upgrade pip \
    && pip install -e git+https://github.com/iPlantCollaborativeOpenSource/python-irodsclient.git@da4daaeee1ad460b5e65ccf9127bfcaad0766950#egg=python_irodsclient

RUN curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g phantomjs-prebuilt

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

# Cleanup
WORKDIR /
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV DEBIAN_FRONTEND teletype
