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

    // ── ustawienia z konfiguracji ────────────────────────────────────────────
    readonly property string sinkName:       plasmoid.configuration.sinkName
    readonly property string portLineout:    plasmoid.configuration.portLineout
    readonly property string portHeadphones: plasmoid.configuration.portHeadphones
    readonly property string labelLineout:   plasmoid.configuration.labelLineout
    readonly property string labelHeadphones: plasmoid.configuration.labelHeadphones

    property string activePort: "unknown"

    // ── odczyt / ustawianie portu ────────────────────────────────────────────
    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var out = data.stdout || ""
                if (out.indexOf(root.portHeadphones) !== -1)
                    root.activePort = "headphones"
                else if (out.indexOf(root.portLineout) !== -1)
                    root.activePort = "lineout"
            }
            disconnectSource(sourceName)
        }

        function queryPort() {
            connectSource("pactl list sinks | grep -A 2 'Active Port' | grep 'Active Port'")
        }

        function setPort(port) {
            connectSource("pactl set-sink-port " + root.sinkName + " " + port)
        }
    }

    function toggle() {
        if (activePort === "headphones") {
            ds.setPort(portLineout)
            activePort = "lineout"
        } else {
            ds.setPort(portHeadphones)
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

    // ── pasek (compact) ──────────────────────────────────────────────────────
    compactRepresentation: Item {
        Layout.preferredWidth: compactRepresentationItem.height  // kwadrat = wysokość paska
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

    // ── pulpit (full) ────────────────────────────────────────────────────────
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

                // ── Port 1 (Headphones) ──────────────────────────────────────
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
                            ds.setPort(root.portHeadphones)
                            root.activePort = "headphones"
                        }
                    }
                }

                // ── Port 2 (Lineout) ─────────────────────────────────────────
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
                            ds.setPort(root.portLineout)
                            root.activePort = "lineout"
                        }
                    }
                }
            }
        }
    }
}
