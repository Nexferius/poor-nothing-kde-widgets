import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation
                             : compactRepresentation

    // ── settings from config ─────────────────────────────────────────────────
    // NOTE: speakers and headphones are treated as two separate PipeWire
    // sinks (e.g. a built-in card + a USB headset), NOT two ports on the
    // same sink. Many setups (like a USB headset) don't expose a port at
    // all, so switching "default sink" is the only thing that reliably works.
    readonly property string sinkSpeakers:    plasmoid.configuration.sinkSpeakers
    readonly property string sinkHeadphones:  plasmoid.configuration.sinkHeadphones
    readonly property string labelLineout:    plasmoid.configuration.labelLineout
    readonly property string labelHeadphones: plasmoid.configuration.labelHeadphones

    property string activePort: "unknown"

    // ── read / set the active sink ───────────────────────────────────────────
    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var out = (data.stdout || "").trim()
                if (out === root.sinkHeadphones)
                    root.activePort = "headphones"
                else if (out === root.sinkSpeakers)
                    root.activePort = "lineout"
            }
            disconnectSource(sourceName)
        }

        function queryPort() {
            connectSource("pactl get-default-sink")
        }

        // Switches the default sink AND moves any already-playing streams
        // over to it, so audio actually follows the switch immediately.
        function setSink(sink) {
            if (!sink) return
            connectSource("pactl set-default-sink '" + sink + "' && pactl list sink-inputs short | cut -f1 | xargs -r -I{} pactl move-sink-input {} '" + sink + "'")
        }
    }

    function toggle() {
        if (activePort === "headphones") {
            ds.setSink(sinkSpeakers)
            activePort = "lineout"
        } else {
            ds.setSink(sinkHeadphones)
            activePort = "headphones"
        }
    }

    Timer {
        interval: plasmoid.configuration.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.queryPort()
    }

    // ── panel (compact) ──────────────────────────────────────────────────────
    compactRepresentation: Item {
        Layout.preferredWidth: compactRepresentationItem.height  // square = bar height
        Layout.preferredHeight: compactRepresentationItem.height

        Image {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: root.activePort === "headphones"
            ? Qt.resolvedUrl("../icons/nothing_speaker.png")
            : Qt.resolvedUrl("../icons/nothing_headphones.png")
            sourceSize.width: 64
            sourceSize.height: 64
            smooth: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle()
        }
    }

    // ── desktop (full) ───────────────────────────────────────────────────────
    fullRepresentation: Item {
        Layout.preferredWidth:  220
        Layout.preferredHeight: 90
        Layout.minimumWidth:    180
        Layout.minimumHeight:   70

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "#1a1a1a"
            radius: (width / height) >= 1.8 ? height / 2 : 18
            clip: true

            // ── slider ───────────────────────────────────────────────────────
            Rectangle {
                id: slider
                width: parent.width / 2
                height: parent.height
                radius: parent.radius
                color: "#292929"
                x: root.activePort === "headphones" ? 0 : parent.width / 2
                Behavior on x {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            Row {
                anchors.fill: parent
                spacing: 0

                // ── Sink 1 (Headphones) ────────────────────────────────────────
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40; height: 40
                            source: Qt.resolvedUrl("../icons/nothing_headphones.png")
                            sourceSize.width: 128; sourceSize.height: 128
                            smooth: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.labelHeadphones
                            font.pixelSize: 9
                            font.letterSpacing: 2
                            color: root.activePort === "headphones" ? "#FF666D" : "#ffffff"
                            font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ds.setSink(root.sinkHeadphones)
                            root.activePort = "headphones"
                        }
                    }
                }

                // ── Sink 2 (Speakers) ───────────────────────────────────────────
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40; height: 40
                            source: Qt.resolvedUrl("../icons/nothing_speaker.png")
                            sourceSize.width: 128; sourceSize.height: 128
                            smooth: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.labelLineout
                            font.pixelSize: 9
                            font.letterSpacing: 2
                            color: root.activePort === "lineout" ? "#FF666D" : "#ffffff"
                            font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ds.setSink(root.sinkSpeakers)
                            root.activePort = "lineout"
                        }
                    }
                }
            }
        }
    }
}
