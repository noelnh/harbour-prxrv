import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/storage.js" as Storage

Page {
    id: settingsPage

    property bool showR18_: Storage.readSetting('showR18')
    property bool rememberMe: Storage.readSetting('rememberMe')

    function saveAccount() {
        if ( customName !== customNameField.text ) {
            if ( customNameField.acceptableInput ) {
                customName = customNameField.text
                Storage.writeSetting('customName', customName)
            } else {
                infoBanner.showText(qsTr('Invalid custom filename!'))
            }
        }
        if ( savePath !== pathField.text ) {
            if (pathField.acceptableInput) {
                savePath = pathField.text
                Storage.writeSetting('savePath', savePath)
            } else {
                infoBanner.showText(qsTr('Invalid save path!'))
            }
        }
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
            if (rememberMe) {
                Storage.writeSetting('passwd', passField.text)
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

        contentHeight: settingsColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Logout")
                onClicked: clearAccount(true)
            }
            MenuItem {
                id: saveAction
                text: qsTr("Save")
                onClicked: {
                    if (debugOn) console.log("saveAction clicked")
                    saveAccount()
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
                text: qsTr("Account")
            }

            TextField {
                id: nameField
                width: 480
                text: JSON.parse(Storage.readSetting("user")).name || ""
                label: qsTr("Username")
                placeholderText: label
            }

            TextField {
                id: passField
                width: 480
                echoMode: TextInput.PasswordEchoOnEdit
                label: qsTr("Password")
                placeholderText: label
            }

            TextSwitch {
                id: saveSwitch
                text: qsTr("Remember me")
                checked: rememberMe
                onCheckedChanged: {
                    Storage.writeSetting('rememberMe', checked)
                }
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

            TextSwitch {
                id: limitSwitch
                text: qsTr("Show R-18 works")
                checked: showR18_
                onCheckedChanged: {
                    Storage.writeSetting('showR18', checked)
                }
            }

            SectionHeader {
                text: qsTr("About")
            }

            Label {
                id: versionLabel
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryColor
                text: qsTr("Version 0.13.2")
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
