#!/bin/bash -e

# Debian builds use the Xfce desktop only.
if [ "${FLAVOR:-xfce}" != xfce ]; then
	echo "Only Debian Xfce is supported" >&2
	exit 1
fi

TARGET_ROOTFS_DIR="${TARGET_ROOTFS_DIR:-binary-xfce}"
ROOTFSIMAGE="${ROOTFSIMAGE:-tboard-debian11-xfce-rootfs.img}"
export ARCH="${ARCH:-${RK_DEBIAN_ARCH:-arm64}}"

./check-resources.sh

echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
	sudo rm ${ROOTFSIMAGE}
fi

for script in ./post-build.sh ../device/rockchip/common/post-build.sh; do
	[ -x $script ] || continue
	sudo $script "$(realpath "$TARGET_ROOTFS_DIR")"
done

# Apparent size + maxium alignment(file_count * block_size) + maxium journal size
IMAGE_SIZE_MB=$(( $(sudo du --apparent-size -sm ${TARGET_ROOTFS_DIR} | cut -f1) + \
	$(sudo find ${TARGET_ROOTFS_DIR} | wc -l) * 4 / 1024 + 64 ))

# Extra 10%
IMAGE_SIZE_MB=$(( $IMAGE_SIZE_MB * 110 / 100 ))

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE} ${IMAGE_SIZE_MB}M

echo Rootfs Image: ${ROOTFSIMAGE}
