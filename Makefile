PACKER_CMD ?= packer
RELEASE ?= stable
VERSION ?= 2765.2.5
DIGEST_URL ?= https://$(RELEASE).release.flatcar-linux.net/amd64-usr/$(VERSION)/flatcar_production_iso_image.iso.DIGESTS
CONFIG ?= flatcar-linux-config.yml
DISK_SIZE ?= 40000
MEMORY ?= 2048
BOOT_WAIT ?= 25s
CT_DOWNLOAD_URL ?= https://github.com/coreos/container-linux-config-transpiler/releases/download
CT_VER ?= v0.9.0
ARCH ?= $(shell uname -m)
HEADLESS ?= false
PASSWORD ?= packer

flatcar-linux: builds/flatcar-$(RELEASE)-$(VERSION)-virtualbox.box

builds/flatcar-$(RELEASE)-$(VERSION)-virtualbox.box:
	$(eval ISO_CHECKSUM := $(shell curl -s "$(DIGEST_URL)" | grep "flatcar_production_iso_image.iso" | awk '{ print length, $$1 | "sort -rg"}' | awk 'NR == 1 { print $$2 }'))

	# Please note that other password hashing methods described at
	# https://kinvolk.io/docs/flatcar-container-linux/latest/provisioning/cl-config/examples/#generating-a-password-hash
	# do not work and therefore steps after reboot will fail as no SSH connection can be done
	$(eval PASSWORD_HASH := $(shell echo "$(PASSWORD)" | openssl passwd -1 -stdin -quiet))

	sed -e "s?PASSWORD_HASH?$(shell echo "$(PASSWORD)" | openssl passwd -1 -stdin -quiet | sed -e 's/\$$/\\$$/g')?" $(CONFIG) | ct -pretty -out-file ignition.json

	$(PACKER_CMD) build -force \
		-var 'flatcar_channel=$(RELEASE)' \
		-var 'flatcar_version=$(VERSION)' \
		-var 'iso_checksum=$(ISO_CHECKSUM)' \
		-var 'iso_checksum_type=sha512' \
		-var 'disk_size=$(DISK_SIZE)' \
		-var 'memory=$(MEMORY)' \
		-var 'boot_wait=$(BOOT_WAIT)' \
		-var 'headless=$(HEADLESS)' \
		-var 'core_user_password=$(PASSWORD)' \
		flatcar-linux.json

clean:
	rm -rf builds

cache-clean:
	rm -rf packer_cache

ct: /usr/local/bin/ct

/usr/local/bin/ct:
	wget $(CT_DOWNLOAD_URL)/$(CT_VER)/ct-$(CT_VER)-$(ARCH)-unknown-linux-gnu -O /usr/local/bin/ct
	chmod +x /usr/local/bin/ct

ct-update: ct-clean ct

ct-clean:
	rm /usr/local/bin/ct

.PHONY: clean cache-clean ct-clean
