import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    width: 400
    height: 300
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property real sharedOpacity: 0.3
    property bool disableSave: true
    property Item textAreaInstance: null
    readonly property var fontWeights: [400, 500, 600, 700]

    function saveNote() {
        var targetArea = root.textAreaInstance;
        if (targetArea && Plasmoid.configuration.noteText !== targetArea.text) {
            Plasmoid.configuration.noteText = targetArea.text;
            var b64Text = Qt.btoa(unescape(encodeURIComponent(targetArea.text)));
            executableDataSource.connectSource("echo '" + b64Text + "' | base64 -d > /home/jmc/.config/plasma-custom-textnote-text.txt; echo 'done'");
        }
    }

    Plasma5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)

            if (sourceName.indexOf("plasma-custom-opacity.txt") !== -1) {
                var stdout = data["stdout"] || "";
                var val = parseFloat(stdout.trim());
                if (!isNaN(val) && val >= 0.0 && val <= 1.0) {
                    if (root.sharedOpacity !== val) {
                        root.sharedOpacity = val;
                    }
                    if (Plasmoid.configuration.bgOpacity !== val) {
                        Plasmoid.configuration.bgOpacity = val;
                    }
                }
            } else if (sourceName.indexOf("plasma-custom-textnote-text.txt") !== -1) {
                if (sourceName.indexOf("cat ") !== -1) {
                    var stdout = data["stdout"] || "";
                    var b64Text = stdout.replace(/\s+/g, '');
                    if (b64Text.length > 0) {
                        try {
                            var decodedText = decodeURIComponent(escape(Qt.atob(b64Text)));
                            var targetArea = root.textAreaInstance;
                            if (targetArea && targetArea.text !== decodedText) {
                                root.disableSave = true;
                                targetArea.text = decodedText;
                            }
                            if (Plasmoid.configuration.noteText !== decodedText) {
                                Plasmoid.configuration.noteText = decodedText;
                            }
                        } catch(e) {
                            console.log("Error decoding text note: " + e);
                        }
                    }
                    root.disableSave = false;
                }
            }
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onBgOpacityChanged() {
            var newOpacity = Plasmoid.configuration.bgOpacity;
            if (Math.abs(root.sharedOpacity - newOpacity) > 0.01) {
                executableDataSource.connectSource("echo " + newOpacity + " > /home/jmc/.config/plasma-custom-opacity.txt; echo 'done'");
            }
        }
    }

    Timer {
        id: startupEnableTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            root.disableSave = false;
        }
    }



    Timer {
        id: sharedOpacityTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executableDataSource.connectSource("cat /home/jmc/.config/plasma-custom-opacity.txt");
        }
    }
    
    compactRepresentation: Item {
        Kirigami.Icon {
            anchors.fill: parent
            source: "text-x-generic"
            active: compactMouse.containsMouse
        }
        
        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }
    
    fullRepresentation: Item {
        Layout.minimumWidth: 209
        Layout.minimumHeight: 150
        Layout.preferredWidth: 209
        Layout.preferredHeight: 300
        
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Plasmoid.configuration.bgOpacity
            radius: 12
        }
        
        QQC2.ScrollView {
            anchors.fill: parent
            anchors.margins: 10
            
            QQC2.TextArea {
                id: textArea
                text: Plasmoid.configuration.noteText
                color: Plasmoid.configuration.textColor
                font.pixelSize: Plasmoid.configuration.textSize
                font.family: Plasmoid.configuration.fontFamily
                font.weight: root.fontWeights[Plasmoid.configuration.fontWeight] || 400
                wrapMode: QQC2.TextArea.Wrap
                selectByMouse: true
                background: Rectangle {
                    color: "transparent"
                }
                onTextChanged: {
                    if (!root.disableSave) {
                        saveTimer.restart()
                    }
                }
                Component.onCompleted: {
                    root.textAreaInstance = textArea;
                }
                Component.onDestruction: {
                    root.saveNote();
                    root.textAreaInstance = null;
                }
            }
        }
        
        Timer {
            id: saveTimer
            interval: 500
            onTriggered: {
                root.saveNote()
            }
        }
    }

    Component.onCompleted: {
        executableDataSource.connectSource("cat /home/jmc/.config/plasma-custom-textnote-text.txt | base64")
    }

    Component.onDestruction: {
        root.saveNote()
    }
}
