import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv

Page {
    id: profilePage

    property string userID: ""
    property string userName: ""
    property string userAccount: ""

    property int leftPadding: 25

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

        if (resp_j['count'] > 0) {
            var _user = resp_j['response'][0]
            userName = _user['name']
            authorIcon.source = _user['profile_image_urls']['px_50x50']
            userAccount = _user['account']
            userWorkLabel.text = "Works (" + _user['stats']['works'] + ")"
            favoriteWorkLabel.text = "Bookmarks (" + _user['stats']['favorites'] + ")"
            latestWorkLabel.text = "Following (" + _user['stats']['following'] + ")"

            for (var title in _user['profile']) {
                if (title === 'contacts') {
                    var contacts = _user['profile']['contacts']
                    if (contacts) {
                        for (var contact in contacts) {
                            if (contacts[contact]) {
                                profileModel.append( {
                                    title: getSubTitle(contact),
                                    content: getContactAddr(contacts[contact], contact)
                                } )
                            }
                        }
                    }
                } else if (title === 'workspace') {
                    // skip
                } else {
                    if (typeof(_user['profile'][title]) !== 'string') continue
                    console.log("append", title)
                    var _content = _user['profile'][title]
                    if (title == 'homepage' && _content.indexOf('http') === 0) {
                        _content = '<a href="' + _content + '">' + _content + '</a>'
                    }
                    profileModel.append( {
                        title: getSubTitle(title),
                        content: _content
                    } )
                }
            }

            if (_user['stats']['works'] == 0) {
                console.log('nav forward')
                pageStack.navigateForward()
            }
        }
    }

    function getContactAddr(addr, site, text) {
        text = text || addr
        if (site === 'twitter') {
            addr = 'https://mobile.twitter.com/' + addr
            return '<a href="' + addr + '">' + text + '</a>'
        } else {
            return addr
        }
    }

    function getSubTitle(title) {
        switch (title) {
            case 'twitter':
                return qsTr("Twitter")
            // TODO other accounts
            case 'job':
                return qsTr("Job")
            case 'introduction':
                return qsTr("Introduction")
            case 'location':
                return qsTr("Location")
            case 'gender':
                return qsTr("Gender")
            // case 'tags'
            case 'homepage':
                return qsTr("Homepage")
            case 'birth_date':
                return qsTr("Birthday")
            case 'blood_type':
                return qsTr("Blood type")
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

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: openWebViewAction
                text: "Open WebView"
                onClicked: {
                    var _props = {"initUrl": "http://touch.pixiv.net/member.php?id=" + userID }
                    pageStack.push('WebViewPage.qml', _props)
                }
            }
            MenuItem {
                text: "Refresh"
                onClicked: {
                    console.log("refreshAction clicked")
                    if (userID) Pixiv.getUser(token, userID, setProfile)
                }
            }
        }

        Item {
            id: column
            width: parent.width
            height: authorBar.height + userWorkItem.height + favoriteWorkItem.height + latestWorkItem.height + userFeedItem.height
            anchors.top: pageHeader.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            BusyIndicator {
                anchors.centerIn: parent
                running: userID == ""
            }

            Item {
                id: authorBar
                width: parent.width
                height: 80
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
                Image {
                    id: authorIcon
                    width: 80
                    height: width
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: leftPadding
                    source: ""
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (currentModel[currentModel.length-1] == "userWorkModel") {
                                console.log('nav back to user work page ' + userID)
                                pageStack.navigateBack()
                            }
                        }
                    }
                }
                Column {
                    width: parent.width - 80
                    height: 80
                    anchors.top: parent.top
                    anchors.left: authorIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    Text {
                        width: parent.width
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignLeft
                        text: userAccount || userName
                    }
                    Text {
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
                    anchors.leftMargin: leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Works"
                }
                onClicked: {
                    if (userID == user['id']) {
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
                    anchors.leftMargin: leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bookmarks"
                }
                onClicked: {
                    currentModel.push("favoriteWorkModel");
                    var _props = {"userID": userID, "userName": userName}
                    pageStack.push("FavoriteWorkPage.qml", _props)
                    goForward()
                }
            }

            ListItem {
                id: latestWorkItem
                width: parent.width
                anchors.top: favoriteWorkItem.bottom
                contentHeight: Theme.itemSizeMedium
                Label {
                    id: latestWorkLabel
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors.left: parent.left
                    anchors.leftMargin: leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Following"
                }
                onClicked: {
                    console.log("goto following users page")
                    if (userID == user['id']) {
                        pageStack.push("FollowingPage.qml")
                    } else {
                        pageStack.push("FollowingPage.qml", {"userID": userID, "userName": userName})
                    }
                    goForward()
                }
            }

            ListItem {
                id: userFeedItem
                width: parent.width
                anchors.top: latestWorkItem.bottom
                contentHeight: Theme.itemSizeMedium
                Label {
                    id: userFeedLabel
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors.left: parent.left
                    anchors.leftMargin: leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Feed"
                }
                onClicked: {
                    console.log("goto user feed page")
                    currentModel.push("feedsModel");
                    pageStack.push("FeedsPage.qml", {"userID": userID, "userName": userName})
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
                    width: parent.width - leftPadding*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: Theme.paddingLarge

                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap
                    text: title
                }
                Label {
                    id: profileContent
                    width: parent.width - leftPadding*2
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
        if (loginCheck() && userID) {
            Pixiv.getUser(token, userID, setProfile)
        }
    }

}

