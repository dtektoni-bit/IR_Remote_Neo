#!/bin/bash
echo "Removing dependencies"
rm -f /etc/lirc/lircrc
apt-get -y purge --auto-remove lirc

# NanoPi NEO specific cleanup
rm -f /etc/systemd/system/lircd.service.d/override.conf
rm -f /etc/systemd/system/irexec.service.d/override.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/lircd.service.d
rmdir --ignore-fail-on-non-empty /etc/systemd/system/irexec.service.d
rm -f /boot/overlay-user/sun8i-h3-gpio-ir.dts
rm -f /boot/overlay-user/sun8i-h3-gpio-ir.dtbo
sed -i 's/ sun8i-h3-gpio-ir//' /boot/armbianEnv.txt
systemctl daemon-reload

CUSTOM_DIR="$(grep "\"name\":" "$(cd "$(dirname "$0")" && pwd -P)"/package.json | cut -d "\"" -f 4)"
if [ "$CUSTOM_DIR" ]; then
  echo "Removing folder for custom LIRC configurations"
  rm -rf /data/INTERNAL/"$CUSTOM_DIR"
fi
echo "Done"
echo "pluginuninstallend"
