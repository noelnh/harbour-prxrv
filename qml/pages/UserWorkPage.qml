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

    property int totalWork: 50
    property int hiddenWork: 0

    property bool isNewModel: true

    property string fromID: ''

    property bool profilePageAttached: false

    ListModel { id: userWorkModel }


    function addProfilePage() {
        if (authorID && !profilePageAttached) {
            if (debugOn) console.log("attach profile page")
            profilePageAttached = true
            var _props = {"userID": authorID, "userName": authorName}
            pageStack.pushAttached("ProfilePage.qml", _props)
        }
    }

    // Set following status
    function setStatus(resp_j) {
        if (resp_j && resp_j['msg'] && resp_j['msg'] == 'ok') {
            if (resp_j['count']) {
                followAction.text = qsTr("Unfollow")
            } else {
                followAction.text = qsTr("Follow")
            }
        } else if (resp_j && resp_j['response']) {
            if (resp_j['response'][0]['is_following']) {
                followAction.text = 'Unfollow'
                // TODO set user details
            } else {
                followAction.text = 'Follow'
            }
        }
    }

    // Add user works to this model
    function addUserWork(resp_j) {

        requestLock = false

        // TODO show info: 404, 0, ...
        if (!resp_j) {
            totalWork = 0
            return
        }

        addProfilePage()

        // authorName is empty if this page is directly loaded from link or id
        if (authorName === '' && resp_j['count']) {
            authorName = resp_j['response'][0]['user']['name']
        }

        totalWork = resp_j['pagination']['total']

        var works = resp_j['response']

        Pixiv.getUser(token, authorID, setStatus)

        if (debugOn) console.log('adding works to userWorkModel')
        for (var i in works) {
            if (!showR18 && works[i]['age_limit'].indexOf('r18') >= 0) {
                hiddenWork += 1
                continue
            }
            userWorkModel.append( {
                workID: works[i]['id'],
                title:  works[i]['title'],
                headerText: works[i]['title'],
                square128: works[i]['image_urls']['px_128x128'],
                master480: works[i]['image_urls']['px_480mw'],
                large: works[i]['image_urls']['large'],
                authorIcon: works[i]['user']['profile_image_urls']['px_50x50'],
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                isManga: works[i]['is_manga'],
                favoriteID: works[i]['favorite_id']
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
                    console.log("unfollow user")
                    Pixiv.unfollowUser(token, authorID, setStatus)
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
                    console.log("follow user " + publicity + "ly")
                    Pixiv.followUser(token, authorID, publicity, setStatus)
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
                    source: "../images/manga-icon.svg"
                }
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: favoriteID ? "../images/btn-done.svg" : "../images/btn-like.svg"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, favoriteID)
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
                            console.log("follow user")
                            pageStack.push(followDialog)
                        } else {
                            console.log("unfollow user")
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
            running: requestLock || ( !userWorkModel.count && (totalWork - hiddenWork) )
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (gridView.atYEnd) {
                console.log('gridView at end')
                if ( !requestLock && userWorkModel.count < totalWork - hiddenWork
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
                console.log("navigated back")
                if (currentModel[currentModel.length-1] == "userWorkModel" && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    console.log("pop model: " + _popModel)
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("onCompleted")
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

