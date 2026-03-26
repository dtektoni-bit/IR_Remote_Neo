#!/bin/bash
# =============================================================================
# install.sh — Volumio IR Controller plugin
# NanoPi NEO / Armbian / Volumio 3 (Nikkov image)
# =============================================================================

exit_cleanup() {
  ERR="$?"
  if [ "$ERR" -ne 0 ]; then
    echo "Plugin failed to install!"
    echo "Cleaning up..."
    if [ -d "$PLUGIN_DIR" ]; then
      [ "$ERR" -eq 1 ] && . ."$PLUGIN_DIR"/uninstall.sh | grep -v "pluginuninstallend"
      echo "Removing plugin directory $PLUGIN_DIR"
      rm -rf "$PLUGIN_DIR"
    else
      echo "Plugin directory could not be found: Cleaning up failed."
    fi
  fi
  echo "plugininstallend"
}
trap "exit_cleanup" EXIT

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd -P)" || { echo "Determination of plugin folder's name failed"; exit 3; }
PLUGIN_TYPE=$(grep "\"plugin_type\":" "$PLUGIN_DIR"/package.json | cut -d "\"" -f 4) || { echo "Determination of plugin type failed"; exit 3; }
PLUGIN_NAME=$(grep "\"name\":" "$PLUGIN_DIR"/package.json | cut -d "\"" -f 4) || { echo "Determination of plugin name failed"; exit 3; }
sed -i "s/\${plugin_type\/plugin_name}/$PLUGIN_TYPE\/$PLUGIN_NAME/" "$PLUGIN_DIR"/UIConfig.json || { echo "Completing UIConfig.json failed"; exit 3; }

REPO="https://raw.githubusercontent.com/dtektoni-bit/IR_Remote_Neo/main"

# --- 1. Починить apt репозиторий ---
echo "Fixing apt repository..."
echo "deb http://archive.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list
apt-get update -q || { echo "apt-get update failed"; exit 3; }

# --- 2. Установить lirc ---
echo "Installing LIRC..."
apt-get -y install lirc || { echo "Installation of lirc failed"; exit 1; }

# --- 3. Скачать и скомпилировать gpio-ir overlay ---
echo "Setting up gpio-ir overlay..."
wget -q -O /boot/overlay-user/sun8i-h3-gpio-ir.dts "${REPO}/overlay-user/sun8i-h3-gpio-ir.dts" || { echo "Downloading gpio-ir dts failed"; exit 1; }
dtc -I dts -O dtb -o /boot/overlay-user/sun8i-h3-gpio-ir.dtbo /boot/overlay-user/sun8i-h3-gpio-ir.dts 2>/dev/null || { echo "Compiling gpio-ir dtbo failed"; exit 1; }

# --- 4. Добавить overlay в armbianEnv.txt ---
echo "Updating armbianEnv.txt..."
if grep -q "user_overlays=" /boot/armbianEnv.txt; then
  if ! grep -q "sun8i-h3-gpio-ir" /boot/armbianEnv.txt; then
    sed -i 's/user_overlays=\(.*\)/user_overlays=\1 sun8i-h3-gpio-ir/' /boot/armbianEnv.txt
  fi
else
  echo "user_overlays=sun8i-h3-gpio-ir" >> /boot/armbianEnv.txt
fi

# --- 5. Закомментировать конфликтующий dtoverlay=gpio-ir ---
echo "Disabling conflicting dtoverlay in userconfig.txt..."
if [ -f /boot/userconfig.txt ]; then
  sed -i 's/^dtoverlay=gpio-ir/#dtoverlay=gpio-ir/' /boot/userconfig.txt
fi

# --- 6. Попытка загрузить overlay без перезагрузки ---
echo "Loading gpio-ir overlay..."
dtoverlay sun8i-h3-gpio-ir 2>/dev/null || true

# --- 7. Настроить lircd ---
echo "Creating lircd override..."
systemctl stop lircd.socket 2>/dev/null || true
systemctl disable lircd.socket 2>/dev/null || true
mkdir -p /etc/systemd/system/lircd.service.d
wget -q -O /etc/systemd/system/lircd.service.d/override.conf "${REPO}/lircd.service.d/override.conf" || { echo "Downloading lircd override failed"; exit 1; }

# --- 8. Настроить irexec ---
echo "Creating irexec override..."
mkdir -p /etc/systemd/system/irexec.service.d
wget -q -O /etc/systemd/system/irexec.service.d/override.conf "${REPO}/irexec.service.d/override.conf" || { echo "Downloading irexec override failed"; exit 1; }

# --- 9. Создать lircrc ---
echo "Creating lircrc file..."
touch /etc/lirc/lircrc || { echo "Creating /etc/lirc/lircrc failed"; exit 1; }
ln -sf /etc/lirc/lircrc /etc/lirc/irexec.lircrc || true

# --- 10. Скопировать конфиги Xtreamer ---
echo "Copying Xtreamer remote config..."
mkdir -p -m 777 /data/INTERNAL/ir_controller/configurations/Xtreamer
