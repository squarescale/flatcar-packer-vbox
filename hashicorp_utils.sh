#!/usr/bin/env bash

set -ex

# python3 -m http.server 8000
# wget http://192.168.1.22:8000/script.sh && bash script.sh

CONSUL_VERSION=${CONSUL_VERSION:-1.9.5}
NOMAD_VERSION=${NOMAD_VERSION:-0.12.12}
LOKI_VERSION=${LOKI_VERSION:-2.2.1}

sudo mkdir -p /opt/bin

# TODO: parametrize linux and amd64 according to uname (-m -s)
# TODO: factorize Hashicorp product same download and extract function
echo -n "Installing Consul ..."
curl -s -L -o /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/consul.zip
rm -f /tmp/consul.zip
echo Done

echo -n "Installing Nomad ..."
curl -s -L -o /tmp/nomad.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/nomad.zip
rm -f /tmp/nomad.zip
echo Done

echo -n "Installing Loki ..."
curl -s -L -o /tmp/loki.zip https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/loki.zip
sudo mv /opt/bin/loki-linux-amd64 /opt/bin/loki
rm -f /tmp/loki.zip
sudo mkdir -p /etc/loki /var/lib/loki

# https://grafana.com/docs/loki/latest/configuration/examples/
# https://github.com/boltdb/bolt
# https://grafana.com/blog/2020/02/19/how-loki-reduces-log-storage/
cat <<EOF | sudo tee /etc/loki/loki.yml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
  - from: 2020-05-15
    store: boltdb
    object_store: filesystem
    schema: v11
    index:
      prefix: index_
      period: 168h

storage_config:
  boltdb:
    directory: /var/lib/loki/index

  filesystem:
    directory: /var/lib/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOF

cat <<EOF | sudo tee /etc/systemd/system/loki.service
[Unit]
Description=Loki Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/bin/loki -config.file /etc/loki/loki.yml

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl enable loki
sudo systemctl start loki
echo Done

echo -n "Installing Promtail ..."
curl -s -L -o /tmp/promtail.zip https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/promtail-linux-amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/promtail.zip
sudo mv /opt/bin/promtail-linux-amd64 /opt/bin/promtail
rm -f /tmp/promtail.zip
sudo mkdir -p /etc/promtail

# From https://gitlab.com/xavki/presentations-loki-fr/-/blob/master/3-installation-promtail/slides.md
cat <<EOF |sudo tee /etc/promtail/promtail.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: /tmp/positions.yaml
client:
  url: http://localhost:3100/loki/api/v1/push
scrape_configs:
  - job_name: nginx
    static_configs:
    - targets:
        - localhost
      labels:
        job: nginx
        env: production
        host: my-test-serv
        __path__: /var/log/nginx/*.log
  - job_name: journal
    journal:
      max_age: 1h
      path: /var/log/journal
      labels:
        job: systemd
        env: production
        host: my-test-serv
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'
EOF

cat <<EOF | sudo tee /etc/systemd/system/promtail.service
[Unit]
Description=Promtail Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/bin/promtail -config.file /etc/promtail/promtail.yml

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl enable promtail
sudo systemctl start promtail
echo Done

echo -n "Installing Logcli ..."
curl -s -L -o /tmp/logcli.zip https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/logcli-linux-amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/logcli.zip
sudo mv /opt/bin/logcli-linux-amd64 /opt/bin/logcli
rm -f /tmp/logcli.zip
echo Done

# Configure of call logcli
# export LOKI_ADDR=http://localhost:3100 logcli
# logcli --addr=http://localhost:3100
# List labels
# logcli labels
# logcli labels host
# Query
# logcli query '{host="my-test-serv",job="nginx"}'
# Tail mode
# logcli query '{host="my-test-serv",job="nginx"}' --tail

echo -n "Installing Docker ..."
sudo systemctl enable docker
sudo systemctl start docker
echo Done

echo -n "Installing cAdvisor ..."
sudo mv /tmp/cadvisor /opt/bin
cat <<EOF | sudo tee /etc/systemd/system/cadvisor.service
[Unit]
Description=cAdvisor containers monitoring from Google
Requires=docker.service
After=docker.service

[Service]
Type=simple
User=root
Group=root
# Default port 8080 is already used by Goss
ExecStart=/opt/bin/cadvisor -port 9101
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cadvisor
sudo systemctl start cadvisor
echo Done
