FROM ubuntu:18.04
LABEL maintainer="Onestein <info@onestein.nl>"

# Define env variables
ENV GIT_BRANCH=12.0 \
  PYTHON_BIN=python3

# Set timezone to UTC
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Generate locales
RUN apt update \
  && apt -yq install locales \
  && locale-gen en_US.UTF-8 \
  && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Create the odoo user
RUN useradd --create-home --home-dir /opt/odoo --no-log-init odoo

# Create folders
RUN mkdir -p /opt/odoo/odoo-server
RUN mkdir -p /opt/odoo/custom

# Set the odoo user as the owner
RUN chown -R odoo:odoo /opt/odoo

# Install APT dependencies
ADD deps/apt.txt /opt/odoo/apt.txt
RUN apt-get update \
  && awk '! /^ *(#|$)/' /opt/odoo/apt.txt | xargs -r apt-get install -yq --no-install-recommends apt-utils
RUN rm /opt/odoo/apt.txt

# Install wkhtmltopdf
RUN set -x; \
apt-get update \
  && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb \
  && dpkg -i wkhtmltox.deb\
  && apt-get -y install \
  && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Add Odoo sources and remove .git folder in order to reduce image size
USER odoo
WORKDIR /opt/odoo/odoo-server
RUN git clone --depth=1 https://github.com/odoo/odoo.git -b $GIT_BRANCH \
  && rm -rf odoo/.git
USER 0

# Install python dependencies
ADD deps/pip.txt /opt/odoo/pip.txt
RUN pip3 install -r /opt/odoo/pip.txt

# Copy entrypoint script and Odoo configuration file
COPY ./bin/entrypoint.sh /opt/odoo/odoo-server/
COPY ./odoo.conf /etc/odoo/
RUN chown odoo:odoo /opt/odoo/odoo-server/entrypoint.sh
RUN chmod +x /opt/odoo/odoo-server/entrypoint.sh
RUN chown odoo:odoo /etc/odoo/odoo.conf

# Mount /opt/odoo/custom/addons for custom addons and /var/lib/odoo for filestore
RUN mkdir -p /opt/odoo/custom/addons \
  && chown -R odoo:odoo /opt/odoo/custom/addons
VOLUME ["/var/lib/odoo", "/opt/odoo/custom/addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/opt/odoo/odoo-server/entrypoint.sh"]
CMD ["/opt/odoo/odoo-server/odoo/odoo-bin"]
