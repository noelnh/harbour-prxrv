import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: followingPage

    property string userID: ""
    property string userName: ""

    property string publicity: 'public'

    property int currentPage: 0
    property bool allLoaded: false

    function setFollowing(resp_j) {

        requestLock = false;
        if (!resp_j) return;

        if (debugOn) console.log("set following", JSON.stringify(resp_j));
        var users = resp_j['user_previews'];
        allLoaded = users.length === 0;

        for (var i in users) {
            followingModel.append( {
                userID: users[i]['user']['id'],
                userName: users[i]['user']['name'],
                userAccount: users[i]['user']['account'],
                userIcon: users[i]['user']['profile_image_urls']['medium']
            } );
        }
    }


    ListModel { id: followingModel }

    SilicaListView {
        id: followingListView

        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            width: parent.width
            title: userName ? qsTr("%1's Following").arg(userName) : qsTr("My Following")
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: changeModeAction
                visible: userID ? false : true
                text: publicity == 'public' ? qsTr("Private following") : qsTr("Public following")
                onClicked: {
                    if (loginCheck()) {
                        followingModel.clear()
                        currentPage = 1
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        Pixiv.getMyFollowing(token, user.id, publicity, currentPage, setFollowing)
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        followingModel.clear()
                        currentPage = 1
                        if (userID) {
                            Pixiv.getFollowing(token, userID, currentPage, setFollowing)
                        } else {
                            Pixiv.getMyFollowing(token, user.id, publicity, currentPage, setFollowing)
                        }
                    }
                }
            }
        }

        model: followingModel

        delegate: ListItem {
            width: parent.width
            contentHeight: Theme.itemSizeMedium

            Image {
                id: authorIcon
                width: Theme.itemSizeSmall
                height: width
                anchors.top: parent.top
                anchors.topMargin: Theme.itemSizeMedium / 2 - Theme.itemSizeSmall / 2
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                source: userIcon
            }

            Column {
                width: parent.width - 80 - Theme.paddingLarge
                height: 80
                anchors.top: parent.top
                anchors.topMargin: Theme.itemSizeMedium / 2 - Theme.itemSizeSmall / 2
                anchors.left: authorIcon.right
                anchors.leftMargin: Theme.paddingMedium
                Label {
                    width: parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignLeft
                    text: userName
                }
                Label {
                    width: parent.width
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignLeft
                    text: userAccount + ' (' + userID + ')'
                }
            }

            onClicked: {
                if ( !requestLock && userID > 0 && loginCheck() ) {
                    if (debugOn) console.log('push to ' + userID)
                    currentModel.push("userWorkModel")
                    var _props = {"authorName": userName, "authorID": userID}
                    pageStack.push("UserWorkPage.qml", _props)
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: requestLock || ( !followingModel.count && !allLoaded )
        }

        onAtYEndChanged: {
            if (followingListView.atYEnd) {
                if (debugOn) console.log('gridView at end')
                if ( !requestLock && followingModel.count > 0 && !allLoaded && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    if (userID) {
                        Pixiv.getFollowing(token, userID, currentPage, setFollowing)
                    } else {
                        Pixiv.getMyFollowing(token, user.id, publicity, currentPage, setFollowing)
                    }
                }
            }
        }

    }


    Component.onCompleted: {
        if (loginCheck() && followingModel.count == 0) {
            currentPage = 1
            if (userID) {
                Pixiv.getFollowing(token, userID, currentPage, setFollowing)
            } else {
                Pixiv.getMyFollowing(token, user.id, publicity, currentPage, setFollowing)
            }
        }
    }
}
