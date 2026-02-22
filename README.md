# Scrcpy Frontend

A Free Pascal / Lazarus GUI front-end for [scrcpy](https://github.com/Genymobile/scrcpy) that lets you scan for ADB devices, connect over TCP/IP, configure all common options, and launch scrcpy with a single click.

![Scrcpy Frontend](https://img.shields.io/badge/Free%20Pascal-Lazarus-blue) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Device scanning** — calls `adb devices` and lists all connected devices
- **TCP/IP connect** — connect to a device wirelessly by IP:Port
- **Version detection** — automatically detects scrcpy v1.x vs v2.x and uses the correct flags for each
- **Live command preview** — shows the exact scrcpy command that will be run as you change options
- **Copy to clipboard** — copy the command to run manually in a terminal
- **Full option coverage** across four tabs:
  - **Display** — bitrate, FPS, resolution, rotation, orientation lock, fullscreen, borderless, always-on-top
  - **Input** — no-control mode, HID keyboard/mouse/gamepad, clipboard autosync, legacy paste
  - **Audio** — disable audio, codec, bitrate, source (v2.x only)
  - **Advanced** — video codec, crop, window title, record to file, power options, verbose/FPS logging, extra arguments

---

## Requirements

| Dependency | Notes |
|---|---|
| [Lazarus IDE](https://www.lazarus-ide.org/) | 2.0 or later recommended |
| Free Pascal Compiler | Included with Lazarus |
| [ADB](https://developer.android.com/tools/adb) | Must be in `PATH` |
| [scrcpy](https://github.com/Genymobile/scrcpy) | v1.x or v2.x, must be in `PATH` |

---

## Building

### With the Lazarus IDE

1. Open `scrcpy_frontend.lpi` in the Lazarus IDE
2. Press **F9** (Build and Run) or **Shift+F9** (Build only)
3. The binary is written to the project directory

### From the command line

```bash
lazbuild scrcpy_frontend.lpi
```

> **Important:** The project does **not** use a `.lfm` designer file. All UI is built entirely in code via the constructor. Do not add a `ComponentName` entry to the `.lpi` or Lazarus will expect a `.lfm` resource and the form will appear blank.

---

## Usage

1. Launch the application
2. Click **Scan Devices** to detect USB-connected Android devices
3. Select a device from the list, or enter an IP:Port and click **Connect** for wireless ADB
4. Adjust options across the Display, Input, Audio, and Advanced tabs
5. Check the **Command Preview** at the bottom to confirm the command
6. Click **Launch** — scrcpy opens in a separate window

### Wireless ADB (TCP/IP)

To connect wirelessly, your device must first be paired over USB:

```bash
adb tcpip 5555
adb connect 192.168.1.xxx:5555
```

After that you can unplug the USB cable and use the TCP Connect field in the app.

---

## Version compatibility

The app detects the installed scrcpy version at startup and the title bar shows which version was found. Flags are automatically adapted:

| Option | scrcpy v1.x | scrcpy v2.x |
|---|---|---|
| Video bitrate | `--bit-rate` | `--video-bit-rate` |
| Audio | not supported | `--audio-bit-rate`, `--audio-codec` |
| Video codec | not supported | `--video-codec` |
| HID keyboard/mouse | not supported | `--keyboard=aoa`, `--mouse=aoa` |

v2.x-only options (Audio tab, HID controls) are silently skipped when running on v1.x.

---

## Project structure

```
scrcpy_frontend.pas   — single-file source (all UI and logic)
scrcpy_frontend.lpi   — Lazarus project file
README.md             — this file
```

---

## License

MIT — do whatever you like with it.
