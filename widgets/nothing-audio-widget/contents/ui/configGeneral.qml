import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Kirigami.FormLayout {
    id: configPage

    property alias cfg_sinkName:       sinkField.text
    property alias cfg_portLineout:    portLineoutField.text
    property alias cfg_portHeadphones: portHeadphonesField.text
    property alias cfg_labelLineout:   labelLineoutField.text
    property alias cfg_labelHeadphones: labelHeadphonesField.text
    property alias cfg_updateInterval: intervalSpin.value

    // ── wykrywanie dostępnych sinków ─────────────────────────────────────────
    P5Support.DataSource {
        id: sinksDs
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var lines = (data.stdout || "").split("\n")
                sinksModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].trim().split(/\s+/)
                    if (parts.length >= 2 && parts[1] !== "") {
                        sinksModel.append({ name: parts[1] })
                    }
                }
            }
            disconnectSource(sourceName)
        }

        function querySinks() {
            connectSource("pactl list sinks short")
        }
    }

    P5Support.DataSource {
        id: portsDs
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var lines = (data.stdout || "").split("\n")
                portsModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    // linia portu zaczyna się od nazwy-portu: Opis
                    var match = line.match(/^(\S+):\s/)
                    if (match) {
                        portsModel.append({ name: match[1] })
                    }
                }
            }
            disconnectSource(sourceName)
        }

        function queryPorts(sink) {
            if (!sink) return
            connectSource("pactl list sinks | grep -A 60 'Name: " + sink + "' | grep -E '^\\s+[a-z].*:.*type:' | awk '{print $1}'")
        }
    }

    ListModel { id: sinksModel }
    ListModel { id: portsModel }

    Component.onCompleted: sinksDs.querySinks()

    // ── Sink ─────────────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Audio Device"
    }

    RowLayout {
        Kirigami.FormData.label: "Sink name:"
        spacing: 6

        QQC2.TextField {
            id: sinkField
            Layout.preferredWidth: 300
            placeholderText: "np. alsa_output.pci-0000_11_00.6.analog-stereo"
        }

        QQC2.Button {
            text: "Detect"
            onClicked: sinksDs.querySinks()
        }
    }

    // lista wykrytych sinków
    ColumnLayout {
        Kirigami.FormData.label: "Detected sinks:"
        visible: sinksModel.count > 0

        Repeater {
            model: sinksModel
            QQC2.Button {
                text: model.name
                flat: true
                onClicked: {
                    sinkField.text = model.name
                    portsDs.queryPorts(model.name)
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Information
            text: "Kliknij sink aby go wybrać i załadować jego porty."
        }
    }

    // ── Porty ────────────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Ports"
    }

    RowLayout {
        Kirigami.FormData.label: "Port 1 (Lineout):"
        spacing: 6

        QQC2.TextField {
            id: portLineoutField
            Layout.preferredWidth: 260
            placeholderText: "np. analog-output-lineout"
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Port 2 (Headphones):"
        spacing: 6

        QQC2.TextField {
            id: portHeadphonesField
            Layout.preferredWidth: 260
            placeholderText: "np. analog-output-headphones"
        }
    }

    // lista wykrytych portów
    ColumnLayout {
        Kirigami.FormData.label: "Detected ports:"
        visible: portsModel.count > 0

        Repeater {
            model: portsModel
            RowLayout {
                QQC2.Button {
                    text: "→ Port 1"
                    flat: true
                    onClicked: portLineoutField.text = model.name
                }
                QQC2.Button {
                    text: "→ Port 2"
                    flat: true
                    onClicked: portHeadphonesField.text = model.name
                }
                QQC2.Label {
                    text: model.name
                    opacity: 0.7
                }
            }
        }
    }

    // ── Etykiety ─────────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Labels"
    }

    QQC2.TextField {
        id: labelLineoutField
        Kirigami.FormData.label: "Label Port 1:"
        placeholderText: "SPEAKERS"
    }

    QQC2.TextField {
        id: labelHeadphonesField
        Kirigami.FormData.label: "Label Port 2:"
        placeholderText: "HEADPHONES"
    }

    // ── Odświeżanie ───────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Advanced"
    }

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: "Update interval (ms):"
        from: 1000
        to: 30000
        stepSize: 500
        editable: true
    }
}
