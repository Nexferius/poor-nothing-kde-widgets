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

    readonly property string sinkName:       "alsa_output.pci-0000_11_00.6.analog-stereo"
    readonly property string portLineout:    "analog-output-lineout"
    readonly property string portHeadphones: "analog-output-headphones"

    property string activePort: "unknown"

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var out = data.stdout || ""
                if (out.indexOf("analog-output-headphones") !== -1)
                    root.activePort = "headphones"
                else if (out.indexOf("analog-output-lineout") !== -1)
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
        interval: 3000
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
        width: Math.min(parent.width, parent.height) * 1
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

            // ── ruchome tło aktywnego przycisku ──────────────────────────────────
            Rectangle {
                id: slider
                width: parent.width / 2
                height: parent.height
                radius: parent.radius
                color: "#292929"

                x: root.activePort === "headphones" ? 0 : parent.width / 2

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Row {
                anchors.fill: parent
                spacing: 0

                // ── HEADPHONES ───────────────────────────────────────────────────
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64; height: 64
                            source: Qt.resolvedUrl("../icons/nothing-speaker.svg")
                            sourceSize.width: 64; sourceSize.height: 64
                            smooth: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "SPEAKERS"
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

                // ── SPEAKERS ─────────────────────────────────────────────────────
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64; height: 64
                            source: Qt.resolvedUrl("../icons/nothing-headphones.svg")
                            sourceSize.width: 64; sourceSize.height: 64
                            smooth: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "HEADPHONES"
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
