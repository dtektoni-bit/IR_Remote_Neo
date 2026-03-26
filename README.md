# IR Remote Controller for NanoPi NEO

Volumio IR Remote Control plugin for NanoPi NEO (Nikkov image, kernel 5.10.60-sunxi).

Uses **gpio-ir-recv** kernel driver via GPIOG9 (pin 18).

## Hardware

| Signal | NanoPi NEO GPIO1 Pin |
|--------|----------------------|
| VCC    | Pin 1 (3.3V)         |
| GND    | Pin 6 (GND)          |
| OUT    | Pin 18 (GPIOG9)      |

⚠️ Do NOT use Pin 11 (PA0) — it is UART2_TX and generates noise.

## Installation

```bash
git clone https://github.com/dtektoni-bit/IR_Remote_Neo
cd IR_Remote_Neo
volumio plugin install
```

After installation — reboot:

```bash
sudo reboot
```

After reboot — open Volumio UI → Plugins → IR Controller → select **Xtreamer**.

## Uninstall

Volumio UI → Plugins → My Plugins → IR Controller → Uninstall.

All system changes will be cleaned up automatically.

## Button mapping (Xtreamer remote)

| Button    | Action                   |
|-----------|--------------------------|
| PLAYPAUSE | Play / Pause             |
| STOP      | Stop                     |
| PAGEUP    | Previous track           |
| PAGEDOWN  | Next track               |
| REWIND    | Seek -10 sec             |
| FORWARD   | Seek +10 sec             |
| RESTART   | Toggle repeat            |
| 1..9      | Play track N from queue  |

## Troubleshooting

| Symptom                  | Solution                                               |
|--------------------------|--------------------------------------------------------|
| /dev/lirc0 missing       | Reboot after installation                              |
| Xtreamer not in list     | Check /data/INTERNAL/ir_controller/configurations/     |
| Commands not executing   | Check irexec: `systemctl status irexec`                |
