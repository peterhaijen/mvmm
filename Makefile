PACKAGE=mvmm
ARCH=all
BUILD_VERSION_FILE := .build-version

# Stabilizing 1.0	  1.0~rc1, 1.0~beta2
# After 1.0 release       1.1~devYYYYMMDD
# Patching 1.0            1.0.1, 1.0.2
# Testing 1.1 pre-release 1.1~beta1, 1.1~rc1
# Final release           1.1, 1.2, etc.

# The version we are working on
VERSION := 1.3
# Uncomment this while the version is in development
VERSION := $(VERSION)~dev$(shell date +%Y%m%d%H%M)

DEB=$(PACKAGE)_$(VERSION)_$(ARCH).deb
BUILD_DIR=$(PACKAGE)_$(VERSION)
SCRIPT := mvmm

all: update-version deb

update-version:
	@echo "Updating $(SCRIPT) to version $(VERSION)"
	@sed -i "s|^our .version = '.*'; *# version-marker: replace-me$$|our \$$version = '$(VERSION)';  # version-marker: replace-me|g" $(SCRIPT)

deb:
	@echo "$(VERSION)" > $(BUILD_VERSION_FILE)
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/DEBIAN
	mkdir -p $(BUILD_DIR)/usr/local/bin
	mkdir -p $(BUILD_DIR)/etc
	mkdir -p $(BUILD_DIR)/etc/systemd/system
	mkdir -p $(BUILD_DIR)/var/lib/mvmm
	mkdir -p $(BUILD_DIR)/usr/share/mvmm/default-configs

	cp mvmm $(BUILD_DIR)/usr/local/bin/mvmm
	cp conf/mvmm.conf $(BUILD_DIR)/usr/share/mvmm/default-configs/mvmm.conf
	cp conf/413.conf $(BUILD_DIR)/usr/share/mvmm/default-configs/902.conf
	cp mvmm.service $(BUILD_DIR)/etc/systemd/system/mvmm.service
	cp DEBIAN/postinst $(BUILD_DIR)/DEBIAN/postinst
	cp DEBIAN/prerm $(BUILD_DIR)/DEBIAN/prerm
	cp DEBIAN/postrm $(BUILD_DIR)/DEBIAN/postrm

	echo "Package: $(PACKAGE)" > $(BUILD_DIR)/DEBIAN/control
	echo "Version: $(VERSION)" >> $(BUILD_DIR)/DEBIAN/control
	echo "Section: admin" >> $(BUILD_DIR)/DEBIAN/control
	echo "Priority: optional" >> $(BUILD_DIR)/DEBIAN/control
	echo "Architecture: $(ARCH)" >> $(BUILD_DIR)/DEBIAN/control
	echo "Maintainer: Peter Haijen <your@email.com>" >> $(BUILD_DIR)/DEBIAN/control
	echo "Depends: perl, libappconfig-perl, libfile-pid-perl" >> $(BUILD_DIR)/DEBIAN/control
	echo "Description: Multi-VM Monitoring Daemon for Proxmox" >> $(BUILD_DIR)/DEBIAN/control

	dpkg-deb --build $(BUILD_DIR) $(DEB)

clean:
	@if [ -f $(BUILD_VERSION_FILE) ]; then \
		V=$$(cat $(BUILD_VERSION_FILE)); \
		echo "Cleaning build for version $$V"; \
		rm -rf $(PACKAGE)_$$V $(PACKAGE)_$$V_$(ARCH).deb $(BUILD_VERSION_FILE); \
	else \
		echo "Cleaning up mvmm_*"; \
		rm -rf mvmm_* $(BUILD_VERSION_FILE); \
	fi

tag:
	@if echo "$(VERSION)" | grep -vq '~dev'; then \
		echo "Tagging version $(VERSION)"; \
		git tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
		git push origin "v$(VERSION)"; \
	else \
		echo "Not tagging dev version: $(VERSION)"; \
		exit 1; \
	fi
