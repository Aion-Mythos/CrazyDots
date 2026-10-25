import QtQuick
import Quickshell
import Quickshell.Io

/**
 * NetworkService.qml
 * Asynchronous backend integration for NetworkManager and system connectivity.
 *
 * Responsibilities:
 * - Probes nmcli availability safely without assuming pre-installed state.
 * - Parses Wi-Fi radio status, active connection, and available SSIDs.
 * - Executes rescans and toggles via structured argument arrays (zero shell concatenation).
 * - Probes Bluetooth daemon status truthfully, exposing inactive states without simulation.
 * - Never stores, logs, or exposes Wi-Fi credentials or passwords.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC REACTIVE PROPERTIES
    // =========================================================================
    property bool isAvailable: false
    property bool wifiEnabled: false
    property bool isConnected: false
    property string connectedSsid: ""
    property int connectedSignal: 0
    property string activeDevice: ""
    property var networks: []
    property bool isScanning: false

    // Bluetooth truthful status
    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false

    signal wifiToggled(bool enabled)
    signal scanCompleted(int networkCount)

    // =========================================================================
    // 1. BACKEND PROBE (which nmcli)
    // =========================================================================
    Process {
        id: probeProc
        command: ["which", "nmcli"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim();
                root.isAvailable = out.length > 0 && out.indexOf("nmcli") !== -1;
                if (root.isAvailable) {
                    root.refreshStatus();
                    root.refreshBluetooth();
                }
            }
        }
    }

    // =========================================================================
    // 2. WI-FI RADIO STATUS PROBE
    // =========================================================================
    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const status = (text || "").trim().toLowerCase();
                root.wifiEnabled = (status === "enabled");
            }
        }
    }

    // =========================================================================
    // 3. DEVICE & CONNECTION STATUS
    // =========================================================================
    Process {
        id: deviceProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (text || "").trim().split("\n");
                let foundWifi = false;
                let activeConn = "";
                let activeDev = "";

                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length >= 4) {
                        const dev = parts[0];
                        const type = parts[1];
                        const state = parts[2];
                        const conn = parts[3];

                        if (type === "wifi") {
                            foundWifi = true;
                            activeDev = dev;
                            if (state === "connected") {
                                activeConn = conn;
                            }
                        }
                    }
                }

                root.activeDevice = activeDev;
                root.isConnected = activeConn.length > 0;
                root.connectedSsid = activeConn;
            }
        }
    }

    // =========================================================================
    // 4. WI-FI NETWORKS LIST SCANNER
    // =========================================================================
    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false;
                const lines = (text || "").trim().split("\n");
                const list = [];
                const seenSsid = {};

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.length === 0) continue;

                    const parts = line.split(":");
                    if (parts.length >= 4) {
                        const inUse = parts[0].trim() === "*";
                        const ssid = parts[1].trim();
                        const signalVal = parseInt(parts[2].trim(), 10) || 0;
                        const security = parts[3].trim() || "Open";

                        if (ssid.length > 0 && !seenSsid[ssid]) {
                            seenSsid[ssid] = true;
                            list.push({
                                inUse: inUse,
                                ssid: ssid,
                                signal: signalVal,
                                security: security
                            });
                            if (inUse) {
                                root.connectedSignal = signalVal;
                                if (!root.connectedSsid || root.connectedSsid.length === 0) {
                                    root.connectedSsid = ssid;
                                    root.isConnected = true;
                                }
                            }
                        }
                    }
                }

                // Sort: in-use network first, then by signal descending
                list.sort((a, b) => {
                    if (a.inUse && !b.inUse) return -1;
                    if (!a.inUse && b.inUse) return 1;
                    return b.signal - a.signal;
                });

                root.networks = list;
                root.scanCompleted(list.length);
            }
        }
    }

    // =========================================================================
    // 5. BLUETOOTH STATUS PROBE
    // =========================================================================
    Process {
        id: btProc
        command: ["systemctl", "is-active", "bluetooth"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const status = (text || "").trim().toLowerCase();
                root.bluetoothAvailable = (status === "active");
                root.bluetoothEnabled = root.bluetoothAvailable;
            }
        }
    }

    // =========================================================================
    // 6. ACTION CONTROLS
    // =========================================================================
    Process {
        id: actionProc
        running: false
        onExited: {
            root.refreshStatus();
        }
    }

    function refreshStatus() {
        if (!root.isAvailable) return;
        wifiRadioProc.running = true;
        deviceProc.running = true;
        root.rescan();
    }

    function refreshBluetooth() {
        btProc.running = true;
    }

    function toggleWifi(): bool {
        if (!root.isAvailable) return false;
        const target = root.wifiEnabled ? "off" : "on";
        actionProc.command = ["nmcli", "radio", "wifi", target];
        actionProc.running = true;
        root.wifiEnabled = !root.wifiEnabled;
        root.wifiToggled(root.wifiEnabled);
        return true;
    }

    function rescan(): bool {
        if (!root.isAvailable || root.isScanning) return false;
        root.isScanning = true;
        wifiScanProc.running = true;
        return true;
    }

    // Periodic poll timer (every 15 seconds) to keep network status synchronized
    Timer {
        id: pollTimer
        interval: 15000
        running: root.isAvailable
        repeat: true
        onTriggered: {
            if (!root.isScanning) {
                root.refreshStatus();
            }
        }
    }

    Component.onCompleted: {
        probeProc.running = true;
    }
}
