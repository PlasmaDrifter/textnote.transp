import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: generalPage
    
    property alias cfg_noteText: noteTextArea.text
    property color cfg_textColor: plasmoid.configuration.textColor
    property alias cfg_textSize: textSizeSpinBox.value
    property alias cfg_bgOpacity: opacitySlider.value
    property string cfg_fontFamily: plasmoid.configuration.fontFamily
    property alias cfg_fontWeight: fontWeightCombo.currentIndex
    
    Kirigami.FormLayout {
        
        RowLayout {
            Kirigami.FormData.label: "Text Color:"
            
            Rectangle {
                id: colorPreview
                width: 50
                height: 30
                border.color: "gray"
                border.width: 1
                radius: 3
                color: generalPage.cfg_textColor
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: colorDialog.open()
                }
            }
            
            QQC2.Label {
                text: generalPage.cfg_textColor
            }
        }
        
        ColorDialog {
            id: colorDialog
            title: "Choose Text Color"
            selectedColor: generalPage.cfg_textColor
            onAccepted: {
                generalPage.cfg_textColor = selectedColor
            }
        }
        
        QQC2.SpinBox {
            id: textSizeSpinBox
            Kirigami.FormData.label: "Text Size:"
            from: 8
            to: 48
            stepSize: 1
        }

        QQC2.ComboBox {
            id: fontFamilyCombo
            Kirigami.FormData.label: "Font Family:"
            model: Qt.fontFamilies().sort()
            Layout.fillWidth: true
            
            Component.onCompleted: {
                var idx = model.indexOf(generalPage.cfg_fontFamily)
                if (idx !== -1) {
                    currentIndex = idx
                }
            }
            
            onActivated: {
                generalPage.cfg_fontFamily = currentText
            }
        }

        Connections {
            target: generalPage
            function onCfg_fontFamilyChanged() {
                var idx = fontFamilyCombo.model.indexOf(generalPage.cfg_fontFamily)
                if (idx !== -1) {
                    fontFamilyCombo.currentIndex = idx
                }
            }
        }

        QQC2.ComboBox {
            id: fontWeightCombo
            Kirigami.FormData.label: "Font weight:"
            model: [
                i18n("Normal"),
                i18n("Medium"),
                i18n("Demi-Bold"),
                i18n("Bold")
            ]
        }
        
        RowLayout {
            Kirigami.FormData.label: "Background Opacity:"
            
            QQC2.Slider {
                id: opacitySlider
                from: 0.0
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            QQC2.Label {
                text: Math.round(opacitySlider.value * 100) + "%"
            }
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }
        
        QQC2.Label {
            Kirigami.FormData.label: "Current Note:"
            text: "(This is stored automatically)"
            font.italic: true
        }
        
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            
            QQC2.TextArea {
                id: noteTextArea
                readOnly: true
                wrapMode: QQC2.TextArea.Wrap
            }
        }
    }
}
