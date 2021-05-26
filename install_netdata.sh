#!/usr/bin/env bash
set -e

DEST="/opt/bin"

/usr/bin/sudo /usr/bin/wget --no-verbose https://my-netdata.io/kickstart-static64.sh -O ${DEST}/kickstart-static64.sh
/usr/bin/sudo /usr/bin/bash ${DEST}/kickstart-static64.sh --non-interactive --stable-channel --dont-start-it
/usr/bin/sudo /usr/bin/rm -rf ${DEST}/kickstart-static64.sh

# Do not launch netdata by default
/usr/bin/sudo /usr/bin/systemctl stop netdata
/usr/bin/sudo /usr/bin/systemctl disable netdata
