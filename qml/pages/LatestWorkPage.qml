import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: latestWorkPage

    property int currentPage: 1
    property int currentIndex: -1


    function addLatestWork(resp_j) {

        requestLock = false;

        if (!resp_j) return;

        var works = resp_j['response'];

        if (debugOn) console.log('adding works to latestWorkModel');
        for (var i in works) {
            if (!showR18 && works[i]['age_limit'].indexOf('r18') >= 0) continue;
            var imgUrls = Prxrv.getImgUrls(works[i])
            latestWorkModel.append({
                workID: works[i]['id'],
                title: works[i]['title'],
                headerText: works[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: works[i]['user']['profile_image_urls']['px_50x50'],
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                authorAccount: works[i]['user']['account'],
                isManga: works[i]['is_manga'],
                favoriteID: works[i]['favorite_id']
            });
        }
    }

    function getWork() {
        Pixiv.getLatestWork(token, currentPage, addLatestWork)
    }

    Component {
        id: latestWorkDelegate

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
                    source: favoriteID ? "../images/btn-done.svg" : "../images/btn-like.svg"
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
                var _props = {"workID": workID, "authorID": authorID, "currentIndex": index}
                pageStack.push("DetailPage.qml", _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: latestWorkModel
        delegate: latestWorkDelegate

        header: PageHeader {
            title: qsTr("Newest Work: All")
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        latestWorkModel.clear()
                        currentPage = 1
                        getWork()
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !latestWorkModel.count
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && latestWorkModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    getWork()
                }
            }
        }

    }

    Component.onCompleted: {
        worksModelStack.push(latestWorkModel)
        if (latestWorkModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                getWork()
            } else {
                // Try again
            }
        }
    }
}


