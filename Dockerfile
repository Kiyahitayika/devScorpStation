FROM i386/debian:buster-slim as base

ENV BYOND_PORT=7777

EXPOSE $BYOND_PORT

#-------------------------------------------------------------------------------
# Install a MariaDB development package for a shared library we'll need later
#-------------------------------------------------------------------------------
FROM base as mariadb_library

#
# Install Debian packages
#
RUN apt-get update && apt-get install -y --no-install-recommends \
    libmariadb-dev \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------------------------------------
# Build TGUI from the JavaScript code using Node
#-------------------------------------------------------------------------------
FROM node:lts-buster as tgui_build

#
# Build tgui -> tgui.bundle.css, tgui.bundle.js
#
COPY . /scorpio
WORKDIR /scorpio/tgui
RUN bin/tgui

#-------------------------------------------------------------------------------
# Build ScorpioStation from the DreamMaker code using BYOND
#-------------------------------------------------------------------------------
FROM scorpiostation/byond:latest as byond_build

ENV LD_LIBRARY_PATH="/byond/bin:${LD_LIBRARY_PATH}"
ENV PATH="/byond/bin:${PATH}"

#
# Build paradise.dme -> paradise.dmb, paradise.rsc
#
COPY . /scorpio
COPY --from=tgui_build /scorpio/tgui/packages/tgui/public /scorpio/tgui/packages/tgui/public
WORKDIR /scorpio
RUN DreamMaker paradise.dme

#-------------------------------------------------------------------------------
# Create the docker image for Scorpio Station
#-------------------------------------------------------------------------------
FROM base as scorpio_image

#
# Install OpenSSL dependency
#
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    && rm -rf /var/lib/apt/lists/*

#
# Create a user to own the files
#
RUN useradd -ms /bin/bash ss13

#
# Copy things into the docker image
#
COPY --chown=ss13:ss13 . /scorpio
COPY --chown=ss13:ss13 --from=tgui_build /scorpio/tgui/packages/tgui/public /scorpio/tgui/packages/tgui/public
COPY --chown=ss13:ss13 --from=scorpiostation/byond:latest /byond /byond
COPY --chown=ss13:ss13 --from=byond_build /scorpio/paradise.dmb /scorpio/paradise.dmb
COPY --chown=ss13:ss13 --from=byond_build /scorpio/paradise.rsc /scorpio/paradise.rsc
COPY --chown=ss13:ss13 --from=scorpiostation/rust-g:latest /rust-g/target/release/librust_g.so /scorpio/librust_g.so
COPY --chown=ss13:ss13 --from=mariadb_library /usr/lib/i386-linux-gnu/libmariadb.so /scorpio/libmariadb.so

#
# Configure the runtime environment for the docker image
#
ENV LD_LIBRARY_PATH="/scorpio:/byond/bin:${LD_LIBRARY_PATH}"
ENV PATH="/byond/bin:${PATH}"
USER ss13
WORKDIR /scorpio

#
# Define the command when the docker image is started
#
ENTRYPOINT DreamDaemon paradise.dmb -port $BYOND_PORT -trusted -close -verbose
