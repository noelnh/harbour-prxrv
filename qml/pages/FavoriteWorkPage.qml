import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: favoriteWorkPage

    property int currentPage: 1
    property int currentIndex: -1

    property string userID: ''
    property string userName: 'undefined'

    property string publicity: 'public'

    property int totalWork: 50
    property int hiddenWork: 0

    property bool isNewModel: true

    ListModel { id: favoriteWorkModel }


    function getTitle() {
        if (userID && userName != 'undefined') {
            return qsTr("%1's Bookmarks").arg(userName)
        } else {
            return qsTr("My Bookmarks")
        }
    }

    function addFavoriteWork(resp_j) {

        requestLock = false;

        if (!resp_j) return;

        totalWork = resp_j['pagination']['total'];
        var favWorks = resp_j['response'];

        if (debugOn) console.log('adding works to favoriteWorkModel');
        for (var i in favWorks) {
            if (!showR18 && favWorks[i]['work']['age_limit'].indexOf('r18') >= 0) {
                hiddenWork += 1
                continue
            }
            favoriteWorkModel.append( {
                workID: favWorks[i]['work']['id'],
                title:  favWorks[i]['work']['title'],
                headerText: favWorks[i]['work']['title'],
                square128: favWorks[i]['work']['image_urls']['px_128x128'],
                master480: favWorks[i]['work']['image_urls']['px_480mw'],
                authorIcon: favWorks[i]['work']['user']['profile_image_urls']['px_50x50'],
                authorID: favWorks[i]['work']['user']['id'],
                authorName: favWorks[i]['work']['user']['name'],
                isManga: favWorks[i]['work']['is_manga'],
                favoriteID: favWorks[i]['work']['favorite_id']
            } );
        }
    }


    Component {
        id: favoriteWorkDelegate

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
                    source: '../images/manga-icon.svg'
                }
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: favoriteID ? '../images/btn-done.svg' : '../images/btn-like.svg'

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

        model: favoriteWorkModel
        delegate: favoriteWorkDelegate

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
                id: changeModeAction
                visible: userID ? false : true
                text: publicity == 'public' ? qsTr("Private bookmarks") : qsTr("Public bookmarks")
                onClicked: {
                    if (loginCheck()) {
                        favoriteWorkModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        Pixiv.getMyFavoriteWork(token, publicity, currentPage, addFavoriteWork)
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        favoriteWorkModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        if (userID) {
                            Pixiv.getFavoriteWork(token, userID, currentPage, addFavoriteWork)
                        } else {
                            Pixiv.getMyFavoriteWork(token, publicity, currentPage, addFavoriteWork)
                        }
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || (!favoriteWorkModel.count && (totalWork - hiddenWork) )
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (gridView.atYEnd) {
                console.log('gridView at end')
                if ( !requestLock && favoriteWorkModel.count < totalWork - hiddenWork
                        && favoriteWorkModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    if (userID) {
                        Pixiv.getFavoriteWork(token, userID, currentPage, addFavoriteWork)
                    } else {
                        Pixiv.getMyFavoriteWork(token, publicity, currentPage, addFavoriteWork)
                    }
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                console.log('navigated back')
                if (currentModel[currentModel.length-1] == 'favoriteWorkModel' && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    console.log('pop model' + _popModel)
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(favoriteWorkModel)
            isNewModel = false
        }
        if (favoriteWorkModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                if (userID) {
                    Pixiv.getFavoriteWork(token, userID, currentPage, addFavoriteWork)
                } else {
                    Pixiv.getMyFavoriteWork(token, publicity, currentPage, addFavoriteWork)
                }
            } else {
                // Try again
            }
        }
    }
}


