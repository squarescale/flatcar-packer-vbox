#!/usr/bin/env bash
set -e

NODE_EXPORTER_VERSION=1.1.2
DEST="/opt/bin"

install-exporter(){
  local exporter="$1"
  local version="$2"
  local exporter_service="$(echo $exporter | tr '_' '-').service"
  cd "$DEST"
  /usr/bin/sudo /usr/bin/wget --no-verbose "https://github.com/prometheus/${exporter}/releases/download/v${version}/${exporter}-${version}.linux-amd64.tar.gz" -O "${DEST}/$exporter.tar.gz"
  /usr/bin/sudo /usr/bin/tar xf "${DEST}/$exporter.tar.gz" "$exporter-$version.linux-amd64/$exporter"
  /usr/bin/sudo /usr/bin/mv "${exporter}-${version}.linux-amd64/${exporter}" "${DEST}/${exporter}"
  /usr/bin/sudo /usr/bin/chmod +x "${DEST}/${exporter}"
  /usr/bin/sudo /usr/bin/chown root.root "${DEST}/${exporter}"
  /usr/bin/sudo /usr/bin/rm -rf "${DEST}/${exporter}.tar.gz" "${exporter}-${version}.linux-amd64"
  /usr/bin/sudo /usr/bin/mv "/tmp/${exporter_service}" "/etc/systemd/system"
  /usr/bin/sudo /usr/bin/systemctl daemon-reload
  /usr/bin/sudo /usr/bin/systemctl enable "${exporter_service}"
  /usr/bin/sudo /usr/bin/systemctl start "${exporter_service}"
}

install-exporter node_exporter ${NODE_EXPORTER_VERSION}
