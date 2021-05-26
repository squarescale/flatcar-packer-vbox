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

echo "Installing CNI plugins ..."
CNI_VERSION=0.9.1
curl -s -L -o /tmp/cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
rm -f /tmp/cni-plugins.tgz
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
echo Done

echo -n "Installing Promtail ..."
curl -s -L -o /tmp/promtail.zip https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/promtail-linux-amd64.zip
sudo unzip -o -q -d /opt/bin /tmp/promtail.zip
sudo mv /opt/bin/promtail-linux-amd64 /opt/bin/promtail
rm -f /tmp/promtail.zip
sudo mkdir -p /etc/promtail

# From https://gitlab.com/xavki/presentations-loki-fr/-/blob/master/3-installation-promtail/slides.md
# /etc/promtail/promtail.yml.sample
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
echo Done
