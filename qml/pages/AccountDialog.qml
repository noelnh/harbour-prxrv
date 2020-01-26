import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/accounts.js" as Accounts

Page {
    // Dialog Component leads to missing global properties in callback setTokenAndConfig()
    id: accountDialog

    // User account name
    property string username: ''

    // User password
    property string password: ''

    // Is new account
    property bool isNew: false

    // Remember password
    property bool rememberMe: true

    // Active
    property bool isActive: true

    function setTokenAndConfig(resp_j) {
        var extraOptions = {
            password: password,
            remember: rememberMe,
            isActive: isActive
        }
        setToken(resp_j, extraOptions, true)
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
            if (!requestLock) {
                requestLock = true
                Pixiv.login(username, password, setTokenAndConfig)
            }
        } else {
            Accounts.update(username, password, rememberMe, isActive)
            // Check active user
            if (isActive) {
                if (user['account'] !== username) {
                    if (!requestLock) {
                        clearCurrentAccount()
                        requestLock = true
                        Pixiv.login(username, password, setTokenAndConfig)
                    }
                } else {
                    loginCheck(username)
                }
            } else {
                currentAccount()
            }
        }
    }

    function resetFields() {
        nameField.text = ""
        passField.text = ""
    }


    SilicaFlickable {
        id: accountFlickable

        contentHeight: accountColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Save")
                onClicked: saveAccount()
            }
        }

        PushUpMenu {
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
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: requestLock
        }

        Column {
            id: accountColumn
            width: parent.width
            height: childrenRect.height

            PageHeader {
                title: isNew ? qsTr("New Account") : qsTr("Edit Account")
            }

            TextField {
                id: nameField
                width: parent.width
                text: username
                label: qsTr("Username")
                placeholderText: label
                inputMethodHints: Qt.ImhNoAutoUppercase
                readOnly: !isNew
                onTextChanged: {
                    username = text;
                }
            }

            TextField {
                id: passField
                width: parent.width
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
                checked: rememberMe
                onCheckedChanged: {
                    rememberMe = checked;
                }
            }

            TextSwitch {
                id: activeSwitch
                text: qsTr("Active")
                checked: isActive
                onCheckedChanged: {
                    isActive = checked;
                }
            }
        }
    }

}

