import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/sites.js" as Sites
import "../js/accounts.js" as Accounts


Dialog {
    id: accountPage

    property string domain: ''
    property string username: ''
    property string _username: ''

    property bool anonymous: false

    property string defaultSiteComboValue: qsTr("select")

    function updateSites() {
        var sites = Sites.findAll();
        sitesModel.clear();
        for (var i = 0; i < sites.length; i++) {
            sitesModel.append(sites[i]);
            if (debugOn) console.log("Found site:", JSON.stringify(sites[i]));
        }
        if (sitesModel.count < 1) {
            defaultSiteComboItem.text = qsTr("Push up to add new site");
        } else {
            defaultSiteComboItem.text = defaultSiteComboValue;
        }
    }

    canAccept: domain || (sitesModel.count > 0 && siteCombo.value !== defaultSiteComboValue)

    ListModel { id: sitesModel }

    SilicaFlickable {
        contentHeight: accountColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PushUpMenu {
            id: pushUpMenu
            MenuItem {
                text: "Add Site"
                onClicked: {
                    pageStack.push("SiteDialog.qml")
                }
            }
        }


        Column {
            id: accountColumn
            width: parent.width

            DialogHeader {
                title: domain ? qsTr("Edit Account") : qsTr("New Account")
            }

            ComboBox {
                id: siteCombo
                width: parent.width
                label: qsTr("Site")
                visible: domain === ''
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem {
                        id: defaultSiteComboItem
                        visible: sitesModel.count < 1
                        text: defaultSiteComboValue
                    }
                    Repeater {
                        id: siteRepeater
                        model: sitesModel
                        delegate: MenuItem {
                            text: domain
                        }
                    }
                }
                onClicked: {
                    console.log(value)
                }

                onValueChanged: {

                }
            }

            TextField {
                id: siteField
                width: parent.width - Theme.paddingLarge
                readOnly: true
                visible: domain !== ''
                text: domain
                label: qsTr("Site domain")
            }

            SectionHeader {
                text: qsTr("Account")
            }

            TextField {
                id: usernameField
                width: parent.width - Theme.paddingLarge
                readOnly: anonymous
                text: username
                label: anonymous ? qsTr("Username (anonymous)") : qsTr("Username (required)")
                placeholderText: label
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            TextField {
                id: passwordField
                width: parent.width - Theme.paddingLarge
                readOnly: anonymous
                echoMode: TextInput.PasswordEchoOnEdit
                label: anonymous ? qsTr("Password (anonymous)") : qsTr("Password (required)")
                placeholderText: label
            }

            TextSwitch {
                id: anonymousSwitch
                text: qsTr("Anonymous")
                checked: anonymous
                onCheckedChanged: {
                    if (checked) {
                        anonymous = true;
                        _username = usernameField.text;
                        usernameField.text = '';
                        passwordField.text = '';
                    } else {
                        anonymous = false;
                        usernameField.text = _username;
                    }
                }
            }

        }
    }


    onAccepted: {
        var oldname = '';

        if (!domain) {  // New account, `domain` is empty
            if (siteCombo.currentIndex >= 0) {
                domain = siteCombo.value;
            } else {
                return;
            }
        } else {
            oldname = username || "--anonymous--";
        }

        if (anonymous || (usernameField.text && passwordField.text)) {
            username = usernameField.text;
            var password = passwordField.text;
            var result = Accounts.saveAccount(utils.sha1, domain, username, password, oldname);
            if (!result) {
                console.log("Failed to save account:", domain, username);
            } else {
                console.log("Account saved:", domain, username);
            }
            toReloadAccounts = true;
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            updateSites();
        }
    }

    Component.onCompleted: {
    }
}
