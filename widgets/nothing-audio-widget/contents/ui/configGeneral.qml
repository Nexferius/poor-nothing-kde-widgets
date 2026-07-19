import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Kirigami.FormLayout {
    id: configPage

    property alias cfg_sinkSpeakers:    speakersField.text
    property alias cfg_sinkHeadphones:  headphonesField.text
    property alias cfg_labelLineout:    labelLineoutField.text
    property alias cfg_labelHeadphones: labelHeadphonesField.text
    property alias cfg_updateInterval:  intervalSpin.value

    // ── detect available sinks ───────────────────────────────────────────────
    // Speakers and headphones are usually two separate PipeWire *sinks*
    // (e.g. a built-in card and a USB headset) rather than two ports on one
    // sink, so this switches the default sink instead of a port.
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

    ListModel { id: sinksModel }

    Component.onCompleted: sinksDs.querySinks()

    // ── Sinks ────────────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Audio Devices"
    }

    RowLayout {
        Kirigami.FormData.label: "Speakers sink name:"
        spacing: 6

        QQC2.TextField {
            id: speakersField
            Layout.preferredWidth: 340
            placeholderText: "e.g. alsa_output.pci-0000_00_1f.3.analog-stereo"
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Headphones sink name:"
        spacing: 6

        QQC2.TextField {
            id: headphonesField
            Layout.preferredWidth: 340
            placeholderText: "e.g. alsa_output.usb-...-00.analog-stereo"
        }

        QQC2.Button {
            text: "Detect"
            onClicked: sinksDs.querySinks()
        }
    }

    // list of detected sinks, click to assign to either field
    ColumnLayout {
        Kirigami.FormData.label: "Detected sinks:"
        visible: sinksModel.count > 0

        Repeater {
            model: sinksModel
            RowLayout {
                QQC2.Button {
                    text: "→ Speakers"
                    flat: true
                    onClicked: speakersField.text = model.name
                }
                QQC2.Button {
                    text: "→ Headphones"
                    flat: true
                    onClicked: headphonesField.text = model.name
                }
                QQC2.Label {
                    text: model.name
                    opacity: 0.7
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Information
            text: "Click a detected sink to assign it to Speakers or Headphones."
        }
    }

    // ── Labels ───────────────────────────────────────────────────────────────
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Labels"
    }

    QQC2.TextField {
        id: labelLineoutField
        Kirigami.FormData.label: "Label (Speakers):"
        placeholderText: "SPEAKERS"
    }

    QQC2.TextField {
        id: labelHeadphonesField
        Kirigami.FormData.label: "Label (Headphones):"
        placeholderText: "HEADPHONES"
    }

    // ── Refresh ──────────────────────────────────────────────────────────────
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
