import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

/**
 * WallpaperSurface.qml
 * Per-monitor desktop wallpaper layer-shell background surface for crazydots.
 *
 * Responsibilities:
 * - Operates as a dedicated layer-shell surface on WlrLayer.Background.
 * - Anchored across the entire screen geometry behind all application windows.
 * - Supports configured wallpaper modes: fill, fit, center, and tile.
 * - Performs smooth cross-fade transitions when the wallpaper image changes.
 * - Handles missing, unreadable, or corrupt image files by falling back to Theme.background.
 * - Loads images asynchronously off the main thread to prevent UI stutter.
 */
PanelWindow {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SCREEN BINDING
    // =========================================================================
    required property var screen

    // Track active image source and fill mode from Config
    readonly property string wallpaperSource: {
        const p = Config.wallpaperCurrent;
        if (!p || p.trim().length === 0) return "";
        return p.startsWith("file://") ? p : ("file://" + p);
    }

    readonly property int activeFillMode: {
        const m = Config.wallpaperMode;
        if (m === "fit") return Image.PreserveAspectFit;
        if (m === "center") return Image.Pad;
        if (m === "tile") return Image.Tile;
        return Image.PreserveAspectCrop; // "fill" default
    }

    // =========================================================================
    // WAYLAND LAYER-SHELL CONFIGURATION
    // =========================================================================
    WlrLayershell.namespace: "crazydots-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Solid fallback color matches active theme background
    color: Theme.background
    mask: Region {}

    Behavior on color {
        ColorAnimation {
            duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }

    // =========================================================================
    // WALLPAPER IMAGE DISPLAY & CROSS-FADE PIPELINE
    // =========================================================================
    Item {
        id: imageContainer
        anchors.fill: parent

        // Primary Active Image
        Image {
            id: currentImage
            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: root.activeFillMode
            asynchronous: true
            cache: true
            visible: status === Image.Ready && root.wallpaperSource.length > 0
            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.durationSlow * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingStandard.type
                    easing.bezierCurve: Tokens.easingStandard.bezierCurve
                }
            }

            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("crazydots: Failed to load wallpaper from:", root.wallpaperSource, "- displaying Theme.background");
                }
            }
        }
    }
}
