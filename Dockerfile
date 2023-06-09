
# Adapted from https://github.com/overhangio/tutor-discovery/blob/84886feaa76e91b0c725566cef503dd2d215979c/tutordiscovery/templates/discovery/build/discovery/Dockerfile
FROM docker.io/ubuntu:20.04 as openedx

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
  apt install -y curl git-core language-pack-en python3 python3-pip python3-venv \
  build-essential libffi-dev libmysqlclient-dev libxml2-dev libxslt-dev libjpeg-dev libssl-dev
ENV LC_ALL en_US.UTF-8

# ARG APP_USER_ID=1000
# RUN useradd --home-dir /openedx --create-home --shell /bin/bash --uid ${APP_USER_ID} app
# USER ${APP_USER_ID}

WORKDIR /openedx/insights

# Setup empty yml config file, which is required by production settings
RUN echo "{}" > /openedx/config.yml
ENV ANALYTICS_DASHBOARD_CFG /openedx/config.yml

# Install python venv
RUN python3 -m venv ../venv/
ENV PATH "/openedx/venv/bin:$PATH"
# https://pypi.org/project/setuptools/
# https://pypi.org/project/pip/
# https://pypi.org/project/wheel/
RUN pip install setuptools==62.1.0 pip==22.0.4 wheel==0.37.1

# Install a recent version of nodejs
RUN pip install nodeenv
# nodejs version picked from https://github.com/openedx/edx-analytics-dashboard/blob/master/README.md
ARG NODE_VERSION=12.11.1
ARG NPM_VERSION=6.11.3
RUN nodeenv /openedx/nodeenv --node=${NODE_VERSION} --npm=${NPM_VERSION} --prebuilt
ENV PATH /openedx/nodeenv/bin:${PATH}

# Copy just JS requirements
COPY insights/package.json package.json
COPY insights/package-lock.json package-lock.json
COPY insights/npm-post-install.sh .

# Install nodejs requirements
ARG NPM_REGISTRY=https://registry.npmjs.org/
RUN npm install --verbose --registry=$NPM_REGISTRY --production
# COPY insights/bower.json bower.json
# RUN ./node_modules/.bin/bower install --allow-root --production

# I don't know why but the npm-post-install.sh script isn't being run on previous statement.
RUN ./npm-post-install.sh

# Copy just Python requirements
COPY insights/requirements/production.txt requirements/production.txt

# Install python requirements
RUN pip install -r requirements/production.txt

# Copy python extra requirements
COPY extra-requirements.txt requirements/extra-requirements.txt

# Install python extra requirements
RUN pip install -r requirements/extra-requirements.txt

# Copy the rest of the code
COPY insights .

# Collect static assets
COPY ./settings/assets.py ./analytics_dashboard/settings/assets.py
RUN DJANGO_SETTINGS_MODULE=analytics_dashboard.settings.assets make static

# copy docker production settings
COPY ./settings/docker_production.py ./analytics_dashboard/settings/docker_production.py

# Run production server
ENV DJANGO_SETTINGS_MODULE course_discovery.settings.docker_production

EXPOSE 8000
CMD uwsgi \
    --static-map /static=/openedx/insights/assets \
    --http 0.0.0.0:8000 \
    --thunder-lock \
    --single-interpreter \
    --enable-threads \
    --processes=2 \
    --buffer-size=8192 \
    --wsgi-file analytics_dashboard/wsgi.py
