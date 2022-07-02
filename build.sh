#!/bin/bash

SKIP_SIZE="68"
BOOT_SIZE="256"
ROOT_SIZE="2748"

ROOTFS_TYPE="ext4"

BOOT_LABEL="BOOT"
ROOT_LABEL="ROOT"

IMG_SIZE="$((SKIP_SIZE + BOOT_SIZE + ROOT_SIZE))"

OUT_FILENAME="ArchLinuxARM-aarch64_S905X"
WORKING_DIR="/tmp/BUILD_DIR"
ARCHLINUXARM_TARBALL_FILE="${WORKING_DIR}/ArchLinuxARM-aarch64.tar.gz"
OUT_DIR="${WORKING_DIR}/BUILD_OUT"
IMG_FILENAME="${OUT_FILENAME}.img"

BOOT_FILES="${WORKING_DIR}/src/boot-files"
PATCH_FILES="${WORKING_DIR}/src/patch"


# Create IMG file

print_err() {
  echo -e "${1}"
  exit 1
}

print_msg() {
  echo -e "${1}"
  exit 1
}

make_image() {
  dd if=/dev/zero of=${IMG_FILENAME} bs=2M count=${IMG_SIZE} conv=fsync >/dev/null 2>&1
  sync

  parted -s ${IMG_FILENAME} mklabel msdos 2>/dev/null
  parted -s ${IMG_FILENAME} mkpart primary fat32 $((SKIP_SIZE))MiB $((SKIP_SIZE + BOOT_SIZE - 1))MiB 2>/dev/null
  parted -s ${IMG_FILENAME} mkpart primary ${ROOTFS_TYPE} $((SKIP_SIZE + BOOT_SIZE))MiB 100% 2>/dev/null
  sync

  LOOP_DEV="$(losetup -P -f --show "${IMG_FILENAME}")"
  [[ -n "${LOOP_DEV}" ]] || echo "losetup ${IMG_FILENAME} failed."

  mkfs.vfat -n ${BOOT_LABEL} ${LOOP_DEV}p1 >/dev/null 2>&1
  if [[ "${ROOTFS_TYPE}" == "btrfs" ]]; then
    mkfs.btrfs -f -U ${ROOTFS_UUID} -L ${ROOT_LABEL} -m single ${LOOP_DEV}p2 >/dev/null 2>&1
  else
    mkfs.ext4 -F -q -U ${ROOTFS_UUID} -L ${ROOT_LABEL} -m 0 ${LOOP_DEV}p2 >/dev/null 2>&1
  fi

  # TODO: Write device bootloader

  mkdir -p mnt/boot

  if ! mount ${LOOP_DEV}p2 mnt; then
    print_err "mount ${LOOP_DEV}p2 failed!"
  fi

  if ! mount ${LOOP_DEV}p1 mnt/boot; then
    print_err "mount ${LOOP_DEV}p1 failed!"
  fi

  cp -a ${BOOT_FILES}/* mnt/boot
  bsdtar -xpf ${ARCHLINUXARM_TARBALL_FILE} -C mnt
  cp -a ${PATCH_FILES}/* mnt/
  sync

  umount -R -f mnt 2>/dev/null
  losetup -d ${LOOP_DEV} 2>/dev/null

  # Compress build IMG and move the file
  gzip -9 ${IMG_FILENAME} && sync && mv "${IMG_FILENAME}.gz ${OUT_DIR}/"
}

cd ${WORKING_DIR}

make_image
