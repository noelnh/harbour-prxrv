import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: worksPage

    property var searchParams: {}
    property string fromTag: ''

    property int currentPage: 1
    property int currentIndex: -1
    property int totalWork: 20
    property int hiddenWork: 0

    property bool isNewModel: true

    ListModel { id: worksSearchModel }

    // Add user works to this model
    function addUserWork(resp_j) {

        requestLock = false;
        if (!resp_j) return;

        totalWork = resp_j['pagination']['total'];
        var works = resp_j['response'];

        if (debugOn) console.log('adding works to worksSearchModel');
        for (var i in works) {
            if (!showR18 && works[i]['age_limit'].indexOf('r18') >= 0) {
                hiddenWork += 1
                continue
            }
            worksSearchModel.append( {
                workID: works[i]['id'],
                title:  works[i]['title'],
                headerText: works[i]['title'],
                square128: works[i]['image_urls']['px_128x128'],
                master480: works[i]['image_urls']['px_480mw'],
                authorIcon: works[i]['user']['profile_image_urls']['px_50x50'],
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                authorAccount: works[i]['user']['account'],
                isManga: works[i]['is_manga'],
                favoriteID: works[i]['favorite_id']
            } );
        }
    }

    Component {
        id: worksSearchDelegate

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
                        }
                    }
                }
            }

            onClicked: {
                var _props = { workID: workID, authorID: authorID, currentIndex: index, fromTag: fromTag }
                pageStack.push("DetailPage.qml", _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: worksSearchModel
        delegate: worksSearchDelegate

        header: PageHeader {
            title: qsTr("Result of ") + searchParams.q
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
                visible: fromTag
                text: qsTr("More options")
                onClicked: { // TODO show dialog instead of replacing
                    // Replace this search result page with trends page and remove this model
                    currentModel.pop()
                    worksModelStack.pop()
                    pageStack.replace("TrendsPage.qml", { searchParams: searchParams })
                }
            }
            MenuItem {
                function getText() {
                    if (searchParams.sort === 'date') {
                        return qsTr("Sort by popularity")
                    } else {
                        return qsTr("Sort by date")
                    }
                }
                text: getText()
                onClicked: {
                    if (loginCheck()) {
                        worksSearchModel.clear()
                        searchParams.sort = (searchParams.sort === 'date' ? 'popular' : 'date')
                        text = getText()
                        currentPage = 1
                        hiddenWork = 0
                        Pixiv.searchWorks(token, searchParams, currentPage, addUserWork)
                    }
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        worksSearchModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        Pixiv.searchWorks(token, searchParams, currentPage, addUserWork)
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || ( !worksSearchModel.count && (totalWork - hiddenWork) )
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && worksSearchModel.count < totalWork - hiddenWork
                        && worksSearchModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    Pixiv.searchWorks(token, searchParams, currentPage, addUserWork)
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Activating &&
                _navigation == PageNavigation.Back &&
                currentModel[currentModel.length-1] == "worksSearchModel") {
            currentPage = 1
            hiddenWork = 0
            Pixiv.searchWorks(token, searchParams, currentPage, addUserWork)
        }
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (currentModel[currentModel.length-1] == "worksSearchModel") {
                    worksModelStack.pop()
                    currentModel.pop()
                    if (debugOn) console.log("pop model: worksSearchModel")
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(worksSearchModel)
            isNewModel = false
        }
        if (worksSearchModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                Pixiv.searchWorks(token, searchParams, currentPage, addUserWork)
            } else {
                // Try again
            }
        }
    }
}


