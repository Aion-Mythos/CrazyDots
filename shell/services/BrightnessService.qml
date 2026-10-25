import QtQuick
import Quickshell
import Quickshell.Io

/**
 * BrightnessService.qml
 * Hardware display backlight control service backed by brightnessctl.
 *
 * Responsibilities:
 * - Probes brightnessctl executable and hardware backlight devices truthfully.
 * - Safely parses machine-readable brightness data (-m).
 * - Modulates brightness with clamp validation (1% to 100%).
 * - Handles desktops and external monitors without backlight hardware by reporting
 *   isAvailable = false and gracefully disabling brightness controls.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool isAvailable: false
    property string deviceName: ""
    property int currentBrightness: 0
    property int maxBrightness: 100
    property int brightnessPercent: 0

    signal brightnessChanged(int percent)
    signal operationFailed(string reason)

    // =========================================================================
    // 1. BACKEND & DEVICE PROBE
    // =========================================================================
    Process {
        id: probeProc
        command: ["brightnessctl", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const line = (text || "").trim().split("\n")[0];
                if (!line || line.indexOf(",") === -1) {
                    root.isAvailable = false;
                    return;
                }

                const parts = line.split(",");
                // Format: device_name,class,current_value,percentage%,max_value
                if (parts.length >= 5 && parts[1] === "backlight") {
                    root.deviceName = parts[0];
                    root.currentBrightness = parseInt(parts[2], 10) || 0;
                    root.brightnessPercent = parseInt(parts[3].replace("%", ""), 10) || 0;
                    root.maxBrightness = parseInt(parts[4], 10) || 100;
                    root.isAvailable = true;
                } else {
                    root.isAvailable = false;
                }
            }
        }
    }

    // =========================================================================
    // 2. BACKLIGHT SETTER PROCESS
    // =========================================================================
    Process {
        id: setProc
        running: false

        onExited: (code) => {
            if (code === 0) {
                probeProc.running = true;
            } else {
                root.operationFailed("brightnessctl exited with code " + code);
            }
        }
    }

    function setBrightness(pct: int): bool {
        if (!root.isAvailable) return false;
        // Clamp to prevent complete display blackouts (min 1%, max 100%)
        const clamped = Math.max(1, Math.min(100, Math.round(pct)));
        root.brightnessPercent = clamped;
        setProc.command = ["brightnessctl", "set", clamped + "%"];
        setProc.running = true;
        root.brightnessChanged(clamped);
        return true;
    }

    function refresh() {
        probeProc.running = true;
    }

    Component.onCompleted: {
        root.refresh();
    }
}
