#!/bin/bash

set -e

usage() {
me=$(basename "$0")
cat << EOF

usage: 
   $me REGISTRATION_CONFIG_FILE [ISO_URL]

REGISTRATION_CONFIG_FILE is the yaml file required by elemental-register in
order to self register against the elemental-operator.

ISO_URL is the URL of an elemental ISO, defaults to community Elemental Teal
ISO releases if not set. I can also be a local path.

EOF
}

abort() {
    >&2 echo "Error: $@"
    usage
    exit 1
}

iso_repack() {
  local TEMPDIR=$(mktemp -d)
  local ISO_FILE=$(basename "${ISO_URL}")
  local REG_FILE="livecd-cloud-config.yaml"

  mkdir -p "${TEMPDIR}/iso"
  mkdir -p "${TEMPDIR}/config"

  [ -f "$(pwd)/${ISO_FILE}" ] && abort "$(pwd)/${ISO_FILE} already exists, aborting"

  case ${ISO_URL} in 
    http*)
      wget -O "${TEMPDIR}/iso/${ISO_FILE}" "${ISO_URL}"
      ;;
    *)
      # Assume it is a local path
      [ -f "${ISO_URL}" ] || abort "${ISO_URL} does not exist, aborting"
      cp "${ISO_URL}" "${TEMPDIR}/iso/${ISO_FILE}" 
      ;;
  esac

  cp "${REG_CONFIG_FILE}" "${TEMPDIR}/config/${REG_FILE}"


  docker pull "${BUILD_IMG}"
  docker run --rm -v ${TEMPDIR}:/mnt -v $(pwd):/output ${BUILD_IMG} \
      xorriso -indev "/mnt/iso/${ISO_FILE}" -outdev "/output/${ISO_FILE}" -map "/mnt/config/${REG_FILE}" "/${REG_FILE}" -boot_image any replay

  rm -rf "${TEMPDIR}"

  echo "ISO generated at $(pwd)/${ISO_FILE}"
}

: ${REPO:=Stable}
: ${ARCH:=$(uname -m)}
# Docker repos only in lowercase
REPOINLOWER=$(echo $REPO | tr '[:upper:]' '[:lower:]')
# This image needs to have xorriso >= 5
: ${BUILD_IMG:=registry.opensuse.org/isv/rancher/elemental/${REPOINLOWER}/teal53/15.4/rancher/elemental-builder-image/5.3:latest}
REG_CONFIG_FILE=${1:-}

# Some systems may report aarch64 as arm64 (darwin for example), so lets consolidate here
# Images on OBS are set as aarch64 so use that for the image link
if [ "$ARCH" == "arm64" ]; then
  ARCH="aarch64"
fi
# Same for amd64 -> x86_64 althougth Im not sure this can happen
if [ "$ARCH" == "amd64" ]; then
  ARCH="x86_64"
fi

ISO_URL=${2:-https://download.opensuse.org/repositories/isv:/Rancher:/Elemental:/${REPO}:/Teal53/media/iso/elemental-teal.${ARCH}.iso}

[ "${REPO}" == "Dev" ] || [ "${REPO}" == "Staging" ] || [ "${REPO}" == "Stable" ] || abort "REPO=${REPO} variable has to match Dev|Staging|Stable, aborting"
[ -n "${REG_CONFIG_FILE}" ] || abort "No registration configuration file provided, aborting"
[ -f "${REG_CONFIG_FILE}" ] || abort "${REG_CONFIG_FILE} does not exist, aborting"

echo "Pulling artifacts from isv:Rancher:Elemental:${REPO} OBS project"

iso_repack
