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
    property int totalFollowing: 0

    property var authorIconUrls: []

    function setFollowing(resp_j) {

        requestLock = false;
        if (!resp_j) return;

        if (debugOn) console.log("set following");
        totalFollowing = resp_j['pagination']['total'];
        var users = resp_j['response'];

        for (var i in users) {
            followingModel.append( {
                userID: users[i]['id'],
                userName: users[i]['name'],
                userAccount: users[i]['account'],
                userIcon: ''
            } );
            authorIconUrls.push(users[i]['profile_image_urls']['px_50x50']);
        }

        Prxrv.getIcon(authorIconUrls);
    }

    function setIcon() {
        for (var i=0; i<authorIconUrls.length; i++) {
            var icon_url = authorIconUrls[i];
            if (!icon_url) continue;
            var icon_path = Prxrv.getIcon(icon_url);
            if (icon_path) {
                followingModel.get(i).userIcon = icon_path;
            }
        }
    }


    ListModel { id: followingModel }

    SilicaListView {
        id: followingListView

        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            width: parent.width
            title: (userName ? userName + "'s " : "My") + "Following"
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: changeModeAction
                visible: userID ? false : true
                text: publicity == 'public' ? "Private follows" : "Public follows"
                onClicked: {
                    if (loginCheck()) {
                        followingModel.clear()
                        currentPage = 1
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        Pixiv.getMyFollowing(token, publicity, currentPage, setFollowing)
                    }
                }
            }
            MenuItem {
                text: "Refresh"
                onClicked: {
                    if (loginCheck()) {
                        followingModel.clear()
                        currentPage = 1
                        if (userID) {
                            Pixiv.getFollowing(token, userID, currentPage, setFollowing)
                        } else {
                            Pixiv.getMyFollowing(token, publicity, currentPage, setFollowing)
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
                width: 80
                height: width
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                source: userIcon
            }

            Column {
                width: parent.width - 80 - Theme.paddingLarge
                height: 80
                anchors.top: parent.top
                anchors.left: authorIcon.right
                anchors.leftMargin: Theme.paddingMedium
                Text {
                    width: parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignLeft
                    text: userName
                }
                Text {
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
            running: requestLock || ( !followingModel.count && totalFollowing )
        }

        onAtYEndChanged: {
            if (followingListView.atYEnd) {
                if (debugOn) console.log('gridView at end')
                if ( !requestLock && followingModel.count > 0 &&
                        followingModel.count < totalFollowing && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    if (userID) {
                        Pixiv.getFollowing(token, userID, currentPage, setFollowing)
                    } else {
                        Pixiv.getMyFollowing(token, publicity, currentPage, setFollowing)
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
                Pixiv.getMyFollowing(token, publicity, currentPage, setFollowing)
            }
        }
        requestMgr.allCacheDone.connect(setIcon);
    }

    Component.onDestruction: {
        requestMgr.allCacheDone.disconnect(setIcon);
    }
}
