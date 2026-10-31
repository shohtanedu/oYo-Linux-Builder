# Optional Broadcom STA installation (oYo only)

The generic builder (`lib/builder.py`) is unchanged. The oYo brand's existing
`85-prepare-broadcom-sta.sh` hook downloads the standalone `broadcom-sta-dkms`
Debian package into the SquashFS. `86-enable-broadcom-setup.sh` enables the
one-shot service added in this patch.

## Device list

`config/40_brand/oYo/overlay/usr/share/openyellowos/offline-drivers/broadcom/wl-pci-ids.txt`
contains one exact `vendor:device` hexadecimal PCI ID per line. For example:

```
14e4:43a0
```

After verifying that a further device really needs `wl`, add another line
(e.g. `14e4:43b1` **only after testing**). Do not add all PCI IDs merely
supported by Broadcom STA: some work better using in-kernel drivers.

## Runtime

1. If none of the approved PCI IDs are present: no APT operation, no module
   change; b44 and the normal Debian driver selection are preserved.
2. If an approved Wi-Fi device is present alongside a Broadcom PCI Ethernet
   adapter: skip STA to avoid Debian's broadcom-sta blacklist disabling b44.
3. Otherwise, if needed: verify the bundled deb's SHA-256, install it using
   offline-only APT sources, let Debian/DKMS build and own the module and
   blacklist, then attempt `modprobe wl`.
4. If the device was already claimed by another driver, stop with a journal
   warning. Do not forcibly unbind devices or unload another device's module.
   Debian recommends reboot after first STA installation; this can prevent
   immediate Wi-Fi use in the current Live session. This limitation needs
   hardware testing before claiming full Live Wi-Fi support.
5. On subsequent boots, the installed package and module are reused. The
   systemd service is oneshot, not a persistent daemon.

The same service is present in the Live and installed systems. Since Calamares
copies the Live root tree, verify that its actual destination contains the
dpkg state, blacklist, DKMS module and bundled deb. Do not assume this has
been established solely by chroot tests.

Secure Boot may reject the DKMS-generated module unless its signing key is
enrolled. The existence of a module signer is not proof the key is trusted.

## Verification

```
python3 -m pytest -q tests/test_oyo_broadcom_setup.py
sh -n config/40_brand/oYo/overlay/usr/libexec/oyo-broadcom-setup.sh
```

After an ISO build:

```
ROOT="$(pwd)/work/chroot"
sudo systemctl --root="$ROOT" is-enabled oyo-broadcom-setup.service
sudo chroot "$ROOT" dpkg-query -W -f='${Status}\n' broadcom-sta-dkms
```

For actual Live testing, check `journalctl -b -u oyo-broadcom-setup` and
`lspci -nnk -d 14e4:43a0`.

**Keep the source build's `work/chroot` free of broadcom-sta-dkms.** Test the
actual offline package install in a separate temporary copy, as in Stage 1.
