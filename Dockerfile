# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.2@sha256:05caead3d2042a3989b9b149565f029dda228bb2a24a0634aef31e95b5bb81ee AS build
RUN \
  --mount=type=bind,from=horizon,source=/,target=/src/horizon,readwrite \
  --mount=type=bind,from=designate-dashboard,source=/,target=/src/designate-dashboard,readwrite \
  --mount=type=bind,from=heat-dashboard,source=/,target=/src/heat-dashboard,readwrite \
  --mount=type=bind,from=ironic-ui,source=/,target=/src/ironic-ui,readwrite \
  --mount=type=bind,from=magnum-ui,source=/,target=/src/magnum-ui,readwrite \
  --mount=type=bind,from=manila-ui,source=/,target=/src/manila-ui,readwrite \
  --mount=type=bind,from=neutron-vpnaas-dashboard,source=/,target=/src/neutron-vpnaas-dashboard,readwrite \
  --mount=type=bind,from=octavia-dashboard,source=/,target=/src/octavia-dashboard,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/designate-dashboard \
        /src/heat-dashboard \
        /src/horizon \
        /src/ironic-ui \
        /src/magnum-ui \
        /src/manila-ui \
        /src/neutron-vpnaas-dashboard \
        /src/octavia-dashboard \
        pymemcache
EOF

FROM ghcr.io/vexxhost/python-base:2024.2@sha256:a48ecdd8a9f45ab75d3bb8d6976b1dae72591aec8618033444e73c84f06126a7
RUN \
    groupadd -g 42424 horizon && \
    useradd -u 42424 -g 42424 -M -d /var/lib/horizon -s /usr/sbin/nologin -c "Horizon User" horizon && \
    mkdir -p /etc/horizon /var/log/horizon /var/lib/horizon /var/cache/horizon && \
    chown -Rv horizon:horizon /etc/horizon /var/log/horizon /var/lib/horizon /var/cache/horizon
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    apache2 gettext libapache2-mod-wsgi-py3
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=build --link /var/lib/openstack /var/lib/openstack
