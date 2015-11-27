import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/storage.js" as Storage

Page {
    id: settingsPage

    property bool showR18_: Storage.readSetting('showR18')

    function saveAccount() {
        if (user['name'] != nameField.text) {
            clearAccount(false)
            if (!nameField.text) {
                nameField.focus = true
                return
            }
            if (!passField.text) {
                passField.focus = true
                return
            }
            Pixiv.login(nameField.text, passField.text, setToken)
        } else {
            loginCheck()
        }
    }

    function clearAccount(clearFields) {
        activityModel.clear()
        latestWorkModel.clear()

        if (clearFields) {
            nameField.text = ""
            passField.text = ""
        }

        user = {}
        token = ""
        expireOn = 0
        showR18 = false

        Storage.writeSetting('user', "{}")
        Storage.writeSetting('token', "")
        Storage.writeSetting('refresh_token', "")
        Storage.writeSetting('expireOn', "0")
        Storage.writeSetting('showR18', showR18)
    }

    SilicaFlickable {
        id: settingsFlickable

        contentHeight: childrenRect.height
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: "Logout"
                onClicked: clearAccount(true)
            }
            MenuItem {
                id: saveAction
                text: "Save"
                onClicked: {
                    if (debugOn) console.log("saveAction clicked")
                    saveAccount()
                }
            }
        }

        Column {
            id: settingsColumn
            width: parent.width

            PageHeader {
                title: "Settings"
            }

            SectionHeader {
                text: "Account"
            }

            TextField {
                id: nameField
                width: 480
                text: JSON.parse(Storage.readSetting("user")).name || ""
                label: "Username"
                placeholderText: label
            }

            TextField {
                id: passField
                width: 480
                echoMode: TextInput.PasswordEchoOnEdit
                label: "Password"
                placeholderText: label
            }

            SectionHeader {
                text: qsTr("Behaviour")
            }

            TextSwitch {
                id: limitSwitch
                text: qsTr("Show R-18 works")
                checked: showR18_
                onCheckedChanged: {
                    Storage.writeSetting('showR18', checked)
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            saveAccount()
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
