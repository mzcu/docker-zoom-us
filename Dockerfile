# References:
#   https://hub.docker.com/r/solarce/zoom-us
#   https://github.com/sameersbn/docker-skype
FROM ubuntu:18.04
MAINTAINER mdouchement


ARG DEBIAN_FRONTEND=noninteractive
ARG ZOOM_URL=https://zoom.us/client/latest/zoom_amd64.deb

# Refresh package lists
RUN apt-get update
RUN apt-get -qy dist-upgrade

# Dependencies for the client .deb
RUN apt-get install -qy curl sudo desktop-file-utils \
libnss3 \
libasound2 \
pkg-config \
libxau-dev \
libxdmcp-dev \
libxcb1-dev \
libxext-dev \
libx11-dev

# nvidia unrecognized opengl version fix

COPY --from=nvidia/opengl:1.0-glvnd-runtime-ubuntu18.04 \
  /usr/lib/x86_64-linux-gnu \
  /usr/lib/x86_64-linux-gnu

COPY --from=nvidia/opengl:1.0-glvnd-runtime-ubuntu18.04 \
  /usr/share/glvnd/egl_vendor.d/10_nvidia.json \
  /usr/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig && \
    echo '/usr/$LIB/libGL.so.1' >> /etc/ld.so.preload && \
    echo '/usr/$LIB/libEGL.so.1' >> /etc/ld.so.preload

ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics


# Grab the client .deb
# Install the client .deb
# Cleanup
RUN curl -sSL $ZOOM_URL -o /tmp/zoom_setup.deb
RUN apt-get install -qy /tmp/zoom_setup.deb
RUN rm /tmp/zoom_setup.deb \
  && rm -rf /var/lib/apt/lists/*

COPY scripts/ /var/cache/zoom-us/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]
