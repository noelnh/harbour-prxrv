import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: profilePage

    property string userID: ""
    property string userName: ""
    property string userAccount: ""
    property var userDetail: null

    property string authorIconSrc: ""


    // for cover index
    property bool beenForward: false

    function goForward() {
        coverIndex.unshift(0)
        beenForward = true
    }

    function setProfile(resp_j) {
        if (!resp_j) return

        if (debugOn) console.log("set profile")
        profileModel.clear()

        var _user = resp_j['user']
        var _profile = resp_j['profile']
        if (_user && _profile) {
            var total_works = _profile['total_illusts'] + _profile['total_manga']
            userName = _user['name']
            authorIconSrc = _user['profile_image_urls']['medium']
            userAccount = _user['account']
            userWorkLabel.text = qsTr("Works (%1)").arg(total_works)
            favoriteWorkLabel.text = qsTr("Bookmarks (%1)").arg(_profile['total_illust_bookmarks_public'])
            followingLabel.text = qsTr("Following (%1)").arg(_profile['total_follow_users'])

            for (var title in _profile) {
                if (!_profile[title] || typeof(_profile[title]) !== 'string') continue
                if (title === 'twitter_url' || title === 'background_image_url') continue
                if (title === 'birth_day' && _profile['birth']) continue

                if (debugOn) console.log("append", title)
                var _content = _profile[title]
                if (title === 'webpage' && _content.indexOf('http') === 0) {
                    _content = '<a href="' + _content + '">' + _content + '</a>'
                } else if (title === 'gender') {
                    _content = _content === 'male' ? qsTr("Male") : _content === 'female' ? qsTr("Female") : _content
                } else if (title === 'twitter_account') {
                    _content = getContactAddr(_profile[title], 'twitter')
                } else if (title === 'pawoo_url') {
                    _content = getContactAddr(_profile[title], 'pawoo')
                }

                profileModel.append( {
                    title: getSubTitle(title),
                    content: _content
                } )
            }

            if (total_works === 0) {
                if (debugOn) console.log('nav forward')
                pageStack.navigateForward()
            }
        }
    }

    function getContactAddr(addr, site, text) {
        if (site === 'twitter') {
            text = text || addr
            addr = 'https://mobile.twitter.com/' + addr
            return '<a href="' + addr + '">' + text + '</a>'
        } else if (site === 'pawoo') {
            return '<a href="' + addr + '">' + userName + '</a>'
        } else {
            return addr
        }
    }

    function getSubTitle(title) {
        switch (title) {
            case 'twitter_account':
                return qsTr("Twitter")
            case 'pawoo_url':
                return qsTr("Pawoo")
            case 'job':
                return qsTr("Job")
            case 'region':
                return qsTr("Location")
            case 'gender':
                return qsTr("Gender")
            case 'webpage':
                return qsTr("Homepage")
            case 'birth':
                return qsTr("Birthday")
            case 'birth_day':
                return qsTr("Birthday")
            default:
                return title
        }
    }


    ListModel { id: profileModel }

    SilicaFlickable {
        id: userListView
        contentHeight: column.height + profileList.height + Theme.paddingLarge*2

        anchors.fill: parent

        PageHeader {
            id: pageHeader
            width: parent.width
            title: userName
        }

        PushUpMenu {
            MenuItem {
                id: openWebViewAction
                text: qsTr("Open Web Page")
                onClicked: {
                    var _props = {"initUrl": "http://touch.pixiv.net/member.php?id=" + userID }
                    pageStack.push('WebViewPage.qml', _props)
                }
            }
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (debugOn) console.log("refreshAction clicked")
                    if (userID) Pixiv.getUser(token, userID, setProfile)
                }
            }
        }

        Item {
            id: column
            width: parent.width
            height: authorBar.height + userWorkItem.height + favoriteWorkItem.height + followingItem.height
            anchors.top: pageHeader.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            BusyIndicator {
                anchors.centerIn: parent
                running: userID == ""
            }

            Item {
                id: authorBar
                width: parent.width - Theme.paddingLarge * 2
                height: Theme.itemSizeSmall
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    id: authorIcon
                    width: parent.height
                    height: parent.height
                    anchors.top: parent.top
                    anchors.left: parent.left
                    source: authorIconSrc
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (currentModel[currentModel.length-1] === "userWorkModel") {
                                if (debugOn) console.log('nav back to user work page ' + userID)
                                pageStack.navigateBack()
                            }
                        }
                    }
                }
                Column {
                    width: parent.width - parent.height - Theme.paddingMedium
                    height: parent.height
                    anchors.top: parent.top
                    anchors.left: authorIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignLeft
                        text: userAccount || userName
                    }
                    Label {
                        width: parent.width
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignLeft
                        text: userID
                    }
                }
            }

            ListItem {
                id: userWorkItem
                width: parent.width
                anchors.top: authorBar.bottom
                anchors.topMargin: Theme.paddingLarge
                contentHeight: Theme.itemSizeMedium
                Label {
                    id: userWorkLabel
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Works")
                }
                onClicked: {
                    if (userID === user['id']) {
                        currentModel.push("userWorkModel")
                        var _props = {"authorName": userName, "authorID": userID}
                        pageStack.push("UserWorkPage.qml", _props)
                        goForward()
                    } else {
                        pageStack.navigateBack()
                    }
                }
            }

            ListItem {
                id: favoriteWorkItem
                width: parent.width
                anchors.top: userWorkItem.bottom
                contentHeight: Theme.itemSizeMedium
                Label {
                    id: favoriteWorkLabel
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Bookmarks")
                }
                onClicked: {
                    currentModel.push("favoriteWorkModel");
                    var _props = {"userID": userID, "userName": userName}
                    pageStack.push("FavoriteWorkPage.qml", _props)
                    goForward()
                }
            }

            ListItem {
                id: followingItem
                width: parent.width
                anchors.top: favoriteWorkItem.bottom
                contentHeight: Theme.itemSizeMedium
                Label {
                    id: followingLabel
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Following")
                }
                onClicked: {
                    if (debugOn) console.log("goto following users page")
                    if (userID === user['id']) {
                        pageStack.push("FollowingPage.qml")
                    } else {
                        pageStack.push("FollowingPage.qml", {"userID": userID, "userName": userName})
                    }
                    goForward()
                }
            }

        }

        ListView {
            id: profileList
            width: parent.width
            height: childrenRect.height + Theme.paddingLarge*4
            anchors.top: column.bottom
            anchors.topMargin: Theme.paddingLarge*2

            model: profileModel

            delegate: Item {
                width: parent.width
                height: childrenRect.height + Theme.paddingLarge*2

                Label {
                    id: profileTitle
                    width: parent.width - Theme.paddingLarge*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: Theme.paddingLarge

                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap
                    text: title
                }
                Label {
                    id: profileContent
                    width: parent.width - Theme.paddingLarge*2
                    anchors.top: profileTitle.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    onLinkActivated: Qt.openUrlExternally(link)
                    wrapMode: Text.WordWrap
                    text: content
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Activating && beenForward) {
            coverIndex.shift()
        }
    }

    Component.onCompleted: {
        if (userDetail) {
            setProfile(userDetail)
        } else if (loginCheck() && userID) {
            Pixiv.getUser(token, userID, setProfile)
        }
    }

}

