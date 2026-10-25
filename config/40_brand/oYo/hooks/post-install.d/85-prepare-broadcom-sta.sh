#!/bin/sh
set -eu

PACKAGE="broadcom-sta-dkms"
DEST="/usr/share/openyellowos/offline-drivers/broadcom"

echo "[oYo] Preparing offline Broadcom STA package..."

# Broadcom STAが標準インストールされていたらビルド失敗
if dpkg-query -W -f='${Status}' "$PACKAGE" 2>/dev/null |
    grep -qx 'install ok installed'; then
    echo "[ERROR] $PACKAGE must not be preinstalled"
    exit 1
fi

# DKMSビルドに必要なコマンドを確認
for cmd in dkms gcc make; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Missing command: $cmd"
        exit 1
    fi
done

# ISOに残るカーネルのヘッダがあるか確認
found_kernel=0
for module_dir in /lib/modules/*; do
    [ -d "$module_dir" ] || continue
    found_kernel=1

    if [ ! -f "$module_dir/build/Makefile" ]; then
        echo "[ERROR] Missing kernel headers: $module_dir"
        exit 1
    fi
done

if [ "$found_kernel" -eq 0 ]; then
    echo "[ERROR] No kernel modules directory found"
    exit 1
fi

# DebianのAPTを使用してdebを取得する
mkdir -p "$DEST"
cd "$DEST"

apt-get download "$PACKAGE"

# 取得したdebが1件だけであることを確認
set -- broadcom-sta-dkms_*.deb

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "[ERROR] Expected exactly one Broadcom STA deb"
    exit 1
fi

# パッケージ名を検証
actual_package="$(dpkg-deb -f "$1" Package)"

if [ "$actual_package" != "$PACKAGE" ]; then
    echo "[ERROR] Unexpected package: $actual_package"
    exit 1
fi

# 検証用チェックサム
sha256sum "$1" > "$1.sha256"

# ダウンロードによってインストールされていないことを再確認
if dpkg-query -W -f='${Status}' "$PACKAGE" 2>/dev/null |
    grep -qx 'install ok installed'; then
    echo "[ERROR] $PACKAGE was unexpectedly installed"
    exit 1
fi

echo "[oYo] Offline Broadcom STA package prepared:"
ls -lh "$1"
