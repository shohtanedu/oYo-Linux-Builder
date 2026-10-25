#!/bin/sh
# This hook is executed inside the build chroot by the generic builder.
set -eu

SERVICE=oyo-broadcom-setup.service
SCRIPT=/usr/libexec/oyo-broadcom-setup.sh
IDS=/usr/share/openyellowos/offline-drivers/broadcom/wl-pci-ids.txt

[ -x "$SCRIPT" ] || { echo "Missing executable: $SCRIPT" >&2; exit 1; }
[ -s "$IDS" ] || { echo "Missing PCI IDs: $IDS" >&2; exit 1; }

systemctl enable "$SERVICE"
echo "[oYo] Enabled $SERVICE for Live and installed systems"
