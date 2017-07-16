import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv
import "../js/settings.js" as Settings
import "../js/accounts.js" as Accounts
import "../js/upgrade.js" as Upgrade

Page {
    id: settingsPage

    property bool showR18_: Settings.read('showR18')

    // User accounts icons
    property var userIconUrls: []

    // Active user
    property int activeCount: 1

    property int cacheSize: 0

    property int leftPadding: 25

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

    function reloadAccounts() {
        Accounts.findAll(function(account) {
            if (!account.account) return;
            account.password = account.password || '';
            account.userIconSrc = '';
            accountModel.append(account);
        }, function() {
            accountModel.clear();
        }, function(users) {
            userIconUrls = [];
            activeCount = 0;
            for (var i=0; i<users.length; i++) {
                if (users[i].isActive) activeCount++;
                try {
                    var user = JSON.parse(users[i].user);
                    var px50 = user["profile_image_urls"]["px_50x50"];
                    if (user && px50) {
                        userIconUrls.push(px50);
                    }
                } catch (err) {
                    console.error("Cannot find icon for user:", users.user)
                }
            }
            setIcon();
        });
    }

    function setIcon() {
        for (var i=0; i<userIconUrls.length; i++) {
            var icon_url = userIconUrls[i];
            icon_url = icon_url || defaultIcon;
            var icon_path = Prxrv.getIcon(icon_url);
            if (icon_path) {
                accountModel.get(i).userIconSrc = icon_path;
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
                text: qsTr("Accounts")
            }

            Label {
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: leftPadding
                }
                visible: activeCount !== 1
                text: qsTr("Set one account as active!")
            }

            ListView {
                id: accountListView
                width: parent.width
                height: childrenRect.height

                model: accountModel

                delegate: ListItem {
                    width: parent.width
                    contentHeight: Theme.itemSizeSmall
                    Item {
                        width: parent.width
                        height: parent.height
                        Image {
                            id: userIcon
                            height: Theme.itemSizeSmall - 8
                            width: height
                            source: userIconSrc
                            anchors {
                                left: parent.left
                                leftMargin: leftPadding
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Label {
                            width: parent.width - leftPadding*3 - Theme.itemSizeSmall
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: isActive ? Theme.highlightColor : Theme.secondaryHighlightColor
                            text: name === account ? account : name + " (" + account + ")"
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            visible: !isActive
                            text: qsTr("Active")
                            onClicked: {
                                loginCheck(account)
                                if (Accounts.change(account)) {
                                    reloadAccounts()
                                }
                            }
                        }
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: removeAccount(account, reloadAccounts)
                        }
                    }
                    onClicked: {
                        pageStack.push("AccountPage.qml", {
                                           username: account,
                                           password: password,
                                           rememberMe: remember,
                                           isActive: isActive
                                       });
                    }
                }
            }

            BackgroundItem {
                height: Theme.itemSizeSmall
                width: parent.width
                Image {
                    id: userAddIcon
                    height: Theme.itemSizeSmall - 8
                    width: height
                    source: "image://theme/icon-m-add"
                    anchors {
                        left: parent.left
                        leftMargin: leftPadding
                        verticalCenter: parent.verticalCenter
                    }
                }
                Label {
                    width: parent.width - leftPadding*3 - Theme.itemSizeSmall
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Add account")
                }
                onClicked: {
                    pageStack.push("AccountPage.qml", {isNew: true})
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
                    Settings.write('showR18', checked)
                }
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
                        leftMargin: leftPadding
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Click to clear cache: ") + (cacheSize || 0) + "KB"
                }
                onClicked: {
                    cacheSize = cacheMgr.clear(cachePath + '/thumbnails', '128x128,480x960');
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
                text: qsTr("Version 0.15.1")
            }

        }

    }

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            reloadAccounts();
        }
        if (status == PageStatus.Deactivating) {
            saveSettings()
            if (showR18_ !== limitSwitch.checked) {
                showR18 = limitSwitch.checked
                activityModel.clear()
                latestWorkModel.clear()
                rankingWorkModel.clear()
                if (debugOn) console.log('showR18', showR18, showR18_)
            }
        }
    }

    Component.onCompleted: {
        requestMgr.allCacheDone.connect(setIcon);
        cacheSize = cacheMgr.getSize(cachePath + '/thumbnails', '') / 1024;
    }

    Component.onDestruction: {
        requestMgr.allCacheDone.disconnect(setIcon);
    }
}
