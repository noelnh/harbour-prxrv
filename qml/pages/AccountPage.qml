import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/settings.js" as Settings
import "../js/accounts.js" as Accounts

Page {
    id: accountsPage

    // User account name
    property string username: ''

    // User password
    property string password: ''

    // Is new account
    property bool isNew: false

    // Remember password
    property bool rememberMe: true

    // Active
    property bool isActive: false

    function setTokenAndConfig(resp_j) {
        var extraOptions = {
            password: password,
            remember: rememberMe,
            isActive: isActive
        }
        setToken(resp_j, extraOptions)
    }

    function saveAccount() {
        if (isNew) {
            if (!nameField.text) {
                nameField.focus = true
                return
            }
            if (!passField.text) {
                passField.focus = true
                return
            }
            Pixiv.login(username, password, setTokenAndConfig)
        } else {
            Accounts.update(username, password, rememberMe, isActive)
            // Check active user
            if (isActive) {
                if (user['account'] !== username) {
                    clearCurrentAccount()
                    Pixiv.login(username, password, setTokenAndConfig)
                } else {
                    loginCheck(username)
                }
            } else {
                readAccount()
            }
        }
    }

    function resetFields() {
        nameField.text = ""
        passField.text = ""
    }

    SilicaFlickable {
        id: settingsFlickable

        contentHeight: settingsColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                visible: isNew
                text: qsTr("Reset")
                onClicked: resetFields()
            }
            MenuItem {
                visible: !isNew
                text: qsTr("Remove")
                onClicked: removeAccount(username, null, true)
            }
            MenuItem {
                id: saveAction
                text: qsTr("Save")
                onClicked: saveAccount()
            }
        }

        Column {
            id: settingsColumn
            width: parent.width
            height: childrenRect.height

            PageHeader {
                title: qsTr("Account")
            }

            TextField {
                id: nameField
                width: 480
                text: username
                label: qsTr("Username")
                placeholderText: label
                readOnly: !isNew
                onTextChanged: {
                    username = text;
                }
            }

            TextField {
                id: passField
                width: 480
                echoMode: TextInput.PasswordEchoOnEdit
                text: password
                label: qsTr("Password")
                placeholderText: label
                onTextChanged: {
                    password = text;
                }
            }

            TextSwitch {
                id: rememberSwitch
                text: qsTr("Remember me")
                visible: false  // TODO refresh_token api is broken
                checked: rememberMe
                onCheckedChanged: {
                    rememberMe = checked;
                }
            }

            TextSwitch {
                id: activeSwitch
                //visible: !isActive
                text: qsTr("Active")
                checked: isActive
                onCheckedChanged: {
                    isActive = checked;
                }
            }
        }
    }

    onStatusChanged: {
    }
}

