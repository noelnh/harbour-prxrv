import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/accounts.js" as Accounts

Page {
    id: accountsPage

    // Active user
    property int activeCount: 1

    function reloadAccounts() {
        Accounts.findAll(function(account) {
            if (!account.account) return;
            account.password = account.password || '';
            try {
                var _user = JSON.parse(account.user);
                account.userIconSrc = _user["profile_image_urls"]["px_50x50"];
            } catch (err) {
                account.userIconSrc = '';
                console.error("Cannot find icon for user:", err)
            }
            accountModel.append(account);
        }, function() {
            accountModel.clear();
        }, function(users) {
            activeCount = 0;
            for (var i=0; i<users.length; i++) {
                if (users[i].isActive) activeCount++;
            }
        });
    }

    SilicaFlickable {
        id: accountsFlickable

        height: accountsColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: reloadAccounts()
            }
        }

        Column {
            id: accountsColumn

            width: parent.width
            height: childrenRect.height

            PageHeader {
                title: qsTr("Accounts")
            }

            Label {
                id: msgLabel
                width: parent.width - Theme.paddingLarge * 2
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
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
                                leftMargin: Theme.paddingLarge
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Label {
                            width: parent.width - Theme.paddingLarge * 3 - parent.height
                            anchors.left: userIcon.right
                            anchors.leftMargin: Theme.paddingLarge
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
                        pageStack.push("AccountDialog.qml", {
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
                        leftMargin: Theme.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                }
                Label {
                    width: parent.width - Theme.paddingLarge * 3 - userAddIcon.width
                    anchors.left: userAddIcon.right
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Add account")
                }
                onClicked: {
                    pageStack.push("AccountDialog.qml", {isNew: true})
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            reloadAccounts();
        }
    }
}
