import QtQuick
import Quickshell
import "../.."
import "../../components"
import "../../services"

/**
 * ConnectivityPopover.qml
 * Compact contextual popover for network, Wi-Fi, and Bluetooth status.
 *
 * Responsibilities:
 * - Displays truthful NetworkManager Wi-Fi status and discovered networks.
 * - Supports one-click Wi-Fi radio toggle and network rescan.
 * - Displays active connection with signal strength glyphs.
 * - Truthfully reports Bluetooth daemon availability without simulated state.
 * - Never logs or exposes passwords.
 */
Item {
    id: root

    property bool active: false
    property var networkService: null

    readonly property bool isNetAvailable: root.networkService ? root.networkService.isAvailable : false
    readonly property bool isWifiOn: root.networkService ? root.networkService.wifiEnabled : false
    readonly property bool isNetConnected: root.networkService ? root.networkService.isConnected : false
    readonly property string netConnectedSsid: root.networkService ? root.networkService.connectedSsid : ""
    readonly property int netConnectedSignal: root.networkService ? root.networkService.connectedSignal : 0
    readonly property var netListModel: (root.networkService && root.networkService.networks) ? root.networkService.networks : []
    readonly property bool isNetScanning: root.networkService ? root.networkService.isScanning : false
    readonly property bool isBtAvailable: root.networkService ? root.networkService.bluetoothAvailable : false

    signal closeRequested()

    implicitWidth: 350
    implicitHeight: 400

    Keys.onEscapePressed: root.closeRequested()

    StyledRect {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Config.themeOpacity)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        // Consume clicks to prevent backdrop dismiss
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.spaceMd
            spacing: Tokens.spaceSm

            // =================================================================
            // 1. HEADER ROW
            // =================================================================
            Row {
                width: parent.width
                height: 30

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖩"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: Theme.accent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CONNECTIVITY"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                    }
                }

                Item {
                    width: parent.width - 180
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: Tokens.radiusFull
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.2) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.error : Theme.border
                    border.width: Tokens.borderWidthThin

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontXs
                        color: closeMouse.containsMouse ? Theme.error : Theme.mutedForeground
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: Tokens.borderWidthThin
                color: Theme.alpha(Theme.border, 0.4)
            }

            // =================================================================
            // 2. WI-FI RADIO & ACTIVE STATUS
            // =================================================================
            Rectangle {
                width: parent.width
                height: 52
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.7)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin

                Row {
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceSm
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!root.isNetAvailable) return "󰖪";
                            if (!root.isWifiOn) return "󰖪";
                            if (root.isNetConnected) return "󰤨";
                            return "󰤯";
                        }
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontLg
                        color: root.isNetConnected ? Theme.accent : Theme.mutedForeground
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 130
                        spacing: 2

                        Text {
                            text: {
                                if (!root.isNetAvailable) return "NetworkManager Unavailable";
                                if (!root.isWifiOn) return "Wi-Fi Disabled";
                                if (root.isNetConnected) return root.netConnectedSsid;
                                return "Disconnected";
                            }
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: {
                                if (!root.isNetAvailable) return "No nmcli backend detected";
                                if (!root.isWifiOn) return "Radio turned off";
                                if (root.isNetConnected) return "Signal: " + root.netConnectedSignal + "%";
                                return "Scanning for networks...";
                            }
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }

                    // Toggle Button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 26
                        radius: Tokens.radiusFull
                        color: root.isWifiOn ? Theme.accent : Theme.alpha(Theme.mutedForeground, 0.25)

                        Text {
                            anchors.centerIn: parent
                            text: root.isWifiOn ? "ON" : "OFF"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: 10
                            font.weight: Tokens.weightBold
                            color: root.isWifiOn ? "#0d0e15" : Theme.foreground
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.networkService) root.networkService.toggleWifi();
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. AVAILABLE NETWORKS LIST
            // =================================================================
            Row {
                width: parent.width
                height: 20

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AVAILABLE NETWORKS (" + root.netListModel.length + ")"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontXs
                    font.weight: Tokens.weightBold
                    color: Theme.mutedForeground
                }

                Item { width: parent.width - 240; height: 1 }

                // Rescan Action
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isNetScanning ? "Scanning..." : "↻ Rescan"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontXs
                    color: rescanMouse.containsMouse ? Theme.accent : Theme.mutedForeground

                    MouseArea {
                        id: rescanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.networkService) root.networkService.rescan();
                        }
                    }
                }
            }

            // Scrollable Networks ListView
            Rectangle {
                width: parent.width
                height: 150
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.4)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin
                clip: true

                ListView {
                    id: netList
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceXs
                    model: root.netListModel
                    spacing: Tokens.spaceXxs
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: netDelegate
                        required property var modelData
                        required property int index

                        width: netList.width
                        height: 32
                        radius: Tokens.radiusSm
                        color: modelData.inUse ? Theme.alpha(Theme.accent, 0.2) : (netMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : "transparent")
                        border.color: modelData.inUse ? Theme.accent : "transparent"
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    const s = netDelegate.modelData.signal;
                                    if (s >= 75) return "󰤨";
                                    if (s >= 50) return "󰤥";
                                    if (s >= 25) return "󰤢";
                                    return "󰤟";
                                }
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontSm
                                color: netDelegate.modelData.inUse ? Theme.accent : Theme.foreground
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: netDelegate.modelData.ssid
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: netDelegate.modelData.inUse ? Tokens.weightBold : Tokens.weightNormal
                                color: netDelegate.modelData.inUse ? Theme.accent : Theme.foreground
                                elide: Text.ElideRight
                                width: parent.width - 120
                            }

                            Item { width: 1; height: 1 }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: netDelegate.modelData.inUse ? "Connected" : netDelegate.modelData.security
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 9
                                color: netDelegate.modelData.inUse ? Theme.accent : Theme.mutedForeground
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        text: root.isWifiOn ? "No networks found" : "Wi-Fi is turned off"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
                        color: Theme.mutedForeground
                        visible: root.netListModel.length === 0
                    }
                }
            }

            // =================================================================
            // 4. BLUETOOTH STATUS
            // =================================================================
            Rectangle {
                width: parent.width
                height: 44
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.7)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin

                Row {
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceSm
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂯"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: root.isBtAvailable ? Theme.accent : Theme.mutedForeground
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 50
                        spacing: 2

                        Text {
                            text: "Bluetooth"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                        }

                        Text {
                            text: root.isBtAvailable ? "Bluetooth Active" : "Service Inactive (systemctl)"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }
                }
            }
        }
    }
}
