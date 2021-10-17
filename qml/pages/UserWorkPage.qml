import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: userWorkPage

    property int currentPage: 1
    property int currentIndex: -1

    property string authorID: ''
    property string authorName: ''

    property bool allLoaded: false
    property int hiddenWork: 0

    property bool isNewModel: true

    property string fromID: ''

    property bool profilePageAttached: false

    ListModel { id: userWorkModel }


    function addProfilePage(detail) {
        if (authorID && !profilePageAttached) {
            if (debugOn) console.log("attach profile page")
            profilePageAttached = true
            var _props = {"userID": authorID, "userName": authorName, "userDetail": detail}
            pageStack.pushAttached("ProfilePage.qml", _props)
        }
    }

    function afterFollow() {
        followAction.text = 'Unfollow'
    }

    function afterUnFollow() {
        followAction.text = 'Follow'
    }

    // Set following status
    function setDetail(resp_j) {
        var author = resp_j && resp_j['user']
        if (author) {
            if (author['is_followed']) {
                followAction.text = qsTr('Unfollow')
            } else {
                followAction.text = qsTr('Follow')
            }
            authorName = author['name']
            addProfilePage(resp_j)
        }
    }

    // Add user works to this model
    function addUserWork(resp_j) {

        requestLock = false

        var works = resp_j['illusts']

        allLoaded = works.length === 0;

        var author = {}
        if (works.length) {
            author = works[0]['user']
            followAction.text = author['is_followed'] ? qsTr('Unfollow') : qsTr('Follow')

            // authorName is empty if this page is directly loaded from link or id
            if (authorName === '') {
                authorName = author['name']
            }
        }

        Pixiv.getUser(token, authorID, setDetail)

        if (debugOn) console.log('adding works to userWorkModel')
        for (var i in works) {
            if ((!showR18 && works[i]['x_restrict'] > 0) || works[i]['sanity_level'] > sanityLevel) {
                hiddenWork += 1
                continue
            }
            var imgUrls = Prxrv.getImgUrls(works[i])
            userWorkModel.append( {
                workID: works[i]['id'],
                title:  works[i]['title'],
                headerText: works[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: works[i]['user']['profile_image_urls']['medium'],
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                authorAccount: works[i]['user']['account'],
                isManga: works[i]['type'] === 'manga',
                isBookmarked: works[i]['is_bookmarked']
            } )
        }
    }

    Component {
        id: unfollowDialog

        Dialog {
            Column {
                width: parent.width

                DialogHeader {}

                Label {
                    id: unfollowLabel
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Unfollow %1?").arg(authorName)
                }
            }
            onDone: {
                if (result == DialogResult.Accepted) {
                    if (debugOn) console.log("unfollow user")
                    Pixiv.unfollowUser(token, authorID, afterUnFollow)
                }
            }
        }
    }

    Component {
        id: followDialog

        Dialog {

            property string publicity: 'public'

            Column {
                width: parent.width

                DialogHeader {}

                TextSwitch {
                    text: qsTr("Follow privately")
                    onCheckedChanged: publicity = ( checked ? 'private' : 'public' )
                }
            }
            onDone: {
                if (result == DialogResult.Accepted) {
                    if (debugOn) console.log("follow user " + publicity + "ly")
                    Pixiv.followUser(token, authorID, publicity, afterFollow)
                }
            }
        }
    }

    Component {
        id: userWorkDelegate

        BackgroundItem {
            width: gridView.cellWidth
            height: width

            Image {
                anchors.centerIn: parent
                width: gridView.cellWidth
                height: width
                source: square128

                Image {
                    visible: isManga
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width / 6
                    height: width
                    source: "../images/manga-icon.svg"
                }
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: isBookmarked ? "../images/btn-done.svg" : "../images/btn-like.svg"
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, !isBookmarked)
                            if (fromID == workID) {
                                refreshWorkDetails = true
                            }
                        }
                    }
                }
            }

            onClicked: {
                var _props = {"workID": workID, "authorID": authorID, "currentIndex": index, "fromID": fromID}
                pageStack.push("DetailPage.qml", _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: userWorkModel
        delegate: userWorkDelegate

        header: PageHeader {
            title: authorName
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Go Home")
                onClicked: {
                    while (currentModel.length) currentModel.pop()
                    while (worksModelStack.length) worksModelStack.pop()
                    pageStack.pop(firstPage)
                }
            }
            MenuItem {
                id: followAction
                text: qsTr("Follow")
                onClicked: {
                    if (loginCheck()) {
                        if (text == qsTr("Follow")) {
                            if (debugOn) console.log("follow user")
                            pageStack.push(followDialog)
                        } else {
                            if (debugOn) console.log("unfollow user")
                            pageStack.push(unfollowDialog)
                        }
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        userWorkModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        Pixiv.getUserWork(token, authorID, currentPage, addUserWork)
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || ( !userWorkModel.count && !allLoaded )
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && !allLoaded
                        && userWorkModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    Pixiv.getUserWork(token, authorID, currentPage, addUserWork)
                }
            }
        }

    }

    onStatusChanged: {
        //if (status == PageStatus.Active) {
        //}
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (debugOn) console.log("navigated back")
                if (currentModel[currentModel.length-1] == "userWorkModel" && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    if (debugOn) console.log("pop model: " + _popModel)
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(userWorkModel)
            isNewModel = false
        }
        if (userWorkModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                Pixiv.getUserWork(token, authorID, currentPage, addUserWork)
            } else {
                // Try again
            }
        }
    }
}

