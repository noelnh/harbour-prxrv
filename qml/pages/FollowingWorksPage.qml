import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: followingWorksPage

    property int currentPage: 1
    property int currentIndex: -1

    property string publicity: 'public'
    property string next_url: ''

    property int hiddenWork: 0

    property bool isNewModel: true

    ListModel { id: followingWorksModel }


    function getTitle() {
        return qsTr("Newest works: Following")
    }

    function addFollowingWorks(resp_j) {

        requestLock = false;

        if (!resp_j) return;

        var followingWorks = resp_j['illusts'];
        next_url = resp_j['next_url'] || ''

        if (debugOn) console.log('adding works to followingWorksModel');
        for (var i in followingWorks) {
            // if (!showR18 && followingWorks[i]['age_limit'].indexOf('r18') >= 0) {
            //     hiddenWork += 1
            //     continue
            // }
            var imgUrls = Prxrv.getImgUrls(followingWorks[i])
            followingWorksModel.append( {
                workID: followingWorks[i]['id'],
                title:  followingWorks[i]['title'],
                headerText: followingWorks[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: followingWorks[i]['user']['profile_image_urls']['medium'],
                authorID: followingWorks[i]['user']['id'],
                authorName: followingWorks[i]['user']['name'],
                authorAccount: followingWorks[i]['user']['account'],
                isManga: followingWorks[i]['page_count'] > 1,
                favoriteID: followingWorks[i]['is_bookmarked'] ? 1 : 0
            } );
        }
    }

    function getFollowingWorks() {
        var params = {
            restrict: publicity,
        }
        Pixiv.getFollowingWorks(token, next_url, params, addFollowingWorks)
    }


    Component {
        id: followingWorksDelegate

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
                    source: '../images/manga-icon.svg'
                }
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: favoriteID ? '../images/btn-done.svg' : '../images/btn-like.svg'
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, favoriteID)
                        }
                    }
                }
            }

            onClicked: {
                var _props = { workID: workID, authorID: authorID, currentIndex: index }
                pageStack.push('DetailPage.qml', _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: followingWorksModel
        delegate: followingWorksDelegate

        header: PageHeader {
            title: getTitle()
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
                text: qsTr("All works")
                onClicked: {
                    currentModel.push("latestWorkModel")
                    pageStack.push("LatestWorkPage.qml")
                }
            }
            MenuItem {
                id: changeModeAction
                text: publicity == 'public' ? qsTr("Private following") : qsTr("Public following")
                onClicked: {
                    if (loginCheck()) {
                        followingWorksModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        next_url = ''
                        getFollowingWorks()
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        followingWorksModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        next_url = ''
                        getFollowingWorks()
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !followingWorksModel.count
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (gridView.atYEnd) {
                if ( !requestLock && next_url && followingWorksModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    getFollowingWorks()
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (currentModel[currentModel.length-1] == 'followingWorksModel' && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    if (debugOn) console.log('pop model' + _popModel)
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(followingWorksModel)
            isNewModel = false
        }
        if (followingWorksModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                next_url = ''
                getFollowingWorks()
            } else {
                // Try again
            }
        }
    }
}


