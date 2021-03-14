import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: favoriteWorkPage

    property int currentPage: 1
    property int currentIndex: -1

    property bool mine: false
    property string userID: ''
    property string userName: 'undefined'

    property string publicity: 'public'
    property string next_url: ''

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

        var favWorks = resp_j['illusts'];
        next_url = resp_j['next_url'] || ''

        if (debugOn) console.log('adding works to favoriteWorkModel');
        for (var i in favWorks) {
            // if (!showR18 && favWorks[i]['age_limit'].indexOf('r18') >= 0) {
            //     hiddenWork += 1
            //     continue
            // }
            var imgUrls = Prxrv.getImgUrls(favWorks[i])
            favoriteWorkModel.append( {
                workID: favWorks[i]['id'],
                title:  favWorks[i]['title'],
                headerText: favWorks[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: favWorks[i]['user']['profile_image_urls']['medium'],
                authorID: favWorks[i]['user']['id'],
                authorName: favWorks[i]['user']['name'],
                authorAccount: favWorks[i]['user']['account'],
                isManga: favWorks[i]['page_count'] > 1,
                favoriteID: favWorks[i]['is_bookmarked'] ? 1 : 0
            } );
        }
    }

    function getFavoriteWorks() {
        var params = {
            user_id: userID,
            restrict: publicity,
        }
        Pixiv.getBookmarks(token, next_url, params, addFavoriteWork)
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
                visible: mine
                text: publicity == 'public' ? qsTr("Private bookmarks") : qsTr("Public bookmarks")
                onClicked: {
                    if (loginCheck()) {
                        favoriteWorkModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        next_url = ''
                        getFavoriteWorks()
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
                        next_url = ''
                        getFavoriteWorks()
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !favoriteWorkModel.count
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (gridView.atYEnd) {
                if ( !requestLock && next_url && favoriteWorkModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    getFavoriteWorks()
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (currentModel[currentModel.length-1] == 'favoriteWorkModel' && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    if (debugOn) console.log('pop model' + _popModel)
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
                next_url = ''
                getFavoriteWorks()
            } else {
                // Try again
            }
        }
    }
}


