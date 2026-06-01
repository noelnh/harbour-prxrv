import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/feed.js" as Feed
import "../js/page-state.js" as PageState
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
        var result = Feed.appendWorks(followingWorks, followingWorksModel, {
            filterHidden: true,
            showR18: showR18,
            sanityLevel: sanityLevel,
            mangaMode: "page_count",
            authorIconMode: "medium"
        })
        hiddenWork += result.hiddenCount
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
                    source: isBookmarked ? '../images/btn-done.svg' : '../images/btn-like.svg'
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, !isBookmarked)
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
                    PageState.goHome(pageStack, firstPage, currentModel, worksModelStack)
                }
            }
            MenuItem {
                id: changeModeAction
                text: publicity == 'public' ? qsTr("Private following") : qsTr("Public following")
                onClicked: {
                    if (loginCheck()) {
                        var state = PageState.resetCursorFeed(followingWorksModel)
                        currentPage = state.currentPage
                        hiddenWork = state.hiddenWork
                        publicity = ( publicity == 'public' ? 'private' : 'public' )
                        next_url = state.nextUrl
                        getFollowingWorks()
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        var state = PageState.resetCursorFeed(followingWorksModel)
                        currentPage = state.currentPage
                        hiddenWork = state.hiddenWork
                        next_url = state.nextUrl
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
                var _popModel = PageState.popWorkModel(currentModel, worksModelStack, "followingWorksModel")
                if (_popModel) {
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
