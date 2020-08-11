# Usage:
#   docker run -ti --publish 8080:80/tcp --publish 8443:443/tcp --name xsshunter xsshunter-christian

FROM ubuntu:bionic
MAINTAINER Christian Lopez <christian@insertco.in>
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y git vim curl python-minimal sudo tmux net-tools

# XSS Hunter dependencies
RUN apt install -y nginx postgresql postgresql-contrib python-virtualenv python-dev libpq-dev libffi-dev python-pip python-psycopg2

WORKDIR /root
RUN git clone git://github.com/phr0nak/xsshunter.git

WORKDIR /root/xsshunter
RUN git checkout christian-stuff

COPY secrets/config.yaml config.yaml

RUN mkdir -p /root/xsshunter/api/uploads
RUN pip install pyaml

WORKDIR /root/xsshunter/api
RUN python -m virtualenv --python=/usr/bin/python /root/xsshunter/api/env
RUN /root/xsshunter/api/env/bin/pip install -r requirements.txt

WORKDIR /root/xsshunter/gui
RUN python -m virtualenv --python=/usr/bin/python /root/xsshunter/gui/env
RUN /root/xsshunter/gui/env/bin/pip install -r requirements.txt

WORKDIR /etc/nginx
RUN mkdir -p ssl
COPY secrets/nginx_xsshunter sites-available/default
COPY secrets/ssl ssl/
RUN /etc/init.d/nginx reload

WORKDIR /
USER postgres
RUN /etc/init.d/postgresql start &&\
    psql template1 -c "CREATE USER xsshunter WITH PASSWORD 'xsshunter';" &&\
    psql template1 -c "CREATE DATABASE xsshunter;"

USER root

# CMD /bin/bash
ENTRYPOINT ["/bin/bash"]

# TODO:
# /etc/init.d/postgresql start
# /etc/init.d/nginx start
# cd /root/xsshunter/api ; . env/bin/activate ; ./apiserver.py
# cd /root/xsshunter/gui ; . env/bin/activate ; ./guiserver.py