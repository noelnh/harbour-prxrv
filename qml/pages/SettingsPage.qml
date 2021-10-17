import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/settings.js" as Settings
import "../js/accounts.js" as Accounts
import "../js/upgrade.js" as Upgrade

Page {
    id: settingsPage

    property bool showR18_: Settings.read('showR18')
    property int sanityLevel_: sanityLevel_

    property int cacheSize: 0
    property bool cacheSized: false

    function saveSettings() {
        if ( customName !== customNameField.text ) {
            if ( customNameField.acceptableInput ) {
                customName = customNameField.text
                Settings.write('customName', customName)
            } else {
                infoBanner.showText(qsTr('Invalid custom filename!'))
            }
        }
        if ( savePath !== pathField.text ) {
            if (pathField.acceptableInput) {
                savePath = pathField.text
                Settings.write('savePath', savePath)
            } else {
                infoBanner.showText(qsTr('Invalid save path!'))
            }
        }
    }

    Component {
        id: resetDialog

        Dialog {

            Column {
                width: parent.width

                DialogHeader {}

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Reset all settings and accounts?")
                }
            }

            onDone: {
                if (result == DialogResult.Accepted) {
                    Upgrade.reset()
                }
            }
        }
    }

    SilicaFlickable {
        id: settingsFlickable

        contentHeight: settingsColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset")
                onClicked: {
                    pageStack.push(resetDialog)
                }
            }
            MenuItem {
                id: saveAction
                text: qsTr("Save")
                onClicked: {
                    if (debugOn) console.log("saveAction clicked")
                    saveSettings()
                }
            }
        }

        Column {
            id: settingsColumn
            width: parent.width
            height: childrenRect.height

            PageHeader {
                title: qsTr("Settings")
            }

            SectionHeader {
                text: qsTr("Download")
            }

            TextField {
                id: pathField
                width: parent.width
                text: savePath
                label: qsTr("Save to")
                placeholderText: label
                validator: RegExpValidator { regExp: /^\/home\/nemo(\/.*|$)/ }
            }

            TextField {
                id: customNameField
                width: parent.width
                text: customName
                label: qsTr("Custom filename, e.g. %a_%u/%i_%t\n%a: artist ID, %u: artist username,\n%n: artist name, %i: work ID, %t: title,\n%i is required.")
                placeholderText: qsTr("Custom filename, e.g. %a_%u/%i_%t")
                validator: RegExpValidator { regExp: /.*%[ti].*/ }
            }

            SectionHeader {
                text: qsTr("Behaviour")
            }

            ComboBox {
                id: sanityCombo
                width: parent.width

                property var values: [3, 5, 7]

                currentIndex: values.indexOf(sanityLevel)

                label: qsTr("Sanity Level")
                menu: ContextMenu {
                    MenuItem { text: '3' }
                    MenuItem { text: '5' }
                    MenuItem { text: '7' }
                }
                onValueChanged: {
                    sanityLevel_ = values[currentIndex]
                    Settings.write('sanityLevel', '' + sanityLevel_)
                    if (sanityLevel_ < 6) {
                        showR18_ = false
                        limitSwitch.checked = false
                        Settings.write('showR18', false)
                    }
                }
            }

            TextSwitch {
                id: limitSwitch
                visible: sanityLevel_ > 6
                text: qsTr("Show R-18 works")
                checked: showR18_
                onCheckedChanged: {
                    Settings.write('showR18', checked)
                }
            }

            TextSwitch {
                id: debugSwitch
                text: qsTr("Debug mode")
                checked: debugOn
                onCheckedChanged: {
                    Settings.write('debugOn', checked)
                }
            }

            TextSwitch {
                id: booruSwitch
                text: qsTr("Moebooru support (Beta)")
                checked: booruEnabled
                enabled: utils.checkBooruInstalled()
                onCheckedChanged: {
                    Settings.write('booruEnabled', checked)
                }
                description: enabled ? '' : qsTr("Please install harbour-mieru")
            }

            SectionHeader {
                text: qsTr("Cache")
            }

            BackgroundItem {
                height: Theme.itemSizeSmall
                width: parent.width
                Label {
                    width: parent.width
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    text: cacheSized ? qsTr("Click to clear cache: ") + (cacheSize || 0) + "KB" : qsTr("Click to get cache size")
                }
                onClicked: {
                    if (cacheSized) {
                        cacheSize = cacheMgr.clear(cachePath, 'thumbnails,icons') / 1024;
                    } else {
                        cacheSize = cacheMgr.getSize(cachePath, 'thumbnails,icons') / 1024;
                        cacheSized = !cacheSized;
                    }
                }
            }

            SectionHeader {
                text: qsTr("About")
            }

            Label {
                id: versionLabel
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryColor
                text: qsTr("Version %1").arg('0.18.0')
            }

        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            saveSettings()
            debugOn = debugSwitch.checked
            booruEnabled = booruSwitch.checked
            sanityLevel = sanityLevel_
            if (showR18_ !== limitSwitch.checked) {
                showR18 = limitSwitch.checked
                activityModel.clear()
                latestWorkModel.clear()
                rankingWorkModel.clear()
                if (debugOn) console.log('showR18', showR18, showR18_)
            }
        }
    }

}
