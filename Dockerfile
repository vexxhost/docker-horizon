# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.2@sha256:f920f5ce0f15fc377200873155c4db02f622a1e4a21058288c2399e35696692e AS build
RUN \
  --mount=type=bind,from=horizon,source=/,target=/src/horizon,readwrite \
  --mount=type=bind,from=designate-dashboard,source=/,target=/src/designate-dashboard,readwrite \
  --mount=type=bind,from=heat-dashboard,source=/,target=/src/heat-dashboard,readwrite \
  --mount=type=bind,from=ironic-ui,source=/,target=/src/ironic-ui,readwrite \
  --mount=type=bind,from=magnum-ui,source=/,target=/src/magnum-ui,readwrite \
  --mount=type=bind,from=manila-ui,source=/,target=/src/manila-ui,readwrite \
  --mount=type=bind,from=neutron-fwaas-dashboard,source=/,target=/src/neutron-fwaas-dashboard,readwrite \
  --mount=type=bind,from=neutron-vpnaas-dashboard,source=/,target=/src/neutron-vpnaas-dashboard,readwrite \
  --mount=type=bind,from=octavia-dashboard,source=/,target=/src/octavia-dashboard,readwrite <<EOF bash -xe
sed -i "s/^os-service-types===.*python_version>='3.10'.*/os-service-types===1.8.2;python_version>='3.10'/" /upper-constraints.txt
sed -i "s/^openstacksdk===.*python_version>='3.10'.*/openstacksdk===4.10.0;python_version>='3.10'/" /upper-constraints.txt
uv pip install \
    --constraint /upper-constraints.txt \
        /src/designate-dashboard \
        /src/heat-dashboard \
        /src/horizon \
        /src/ironic-ui \
        /src/magnum-ui \
        /src/manila-ui \
        /src/neutron-fwaas-dashboard \
        /src/neutron-vpnaas-dashboard \
        /src/octavia-dashboard \
        pymemcache
EOF

FROM ghcr.io/vexxhost/python-base:2025.2@sha256:ff4c5b3f26d6026788b881d077ac7a7d935f09760b2a9e3d1502f0a4f0398720
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
