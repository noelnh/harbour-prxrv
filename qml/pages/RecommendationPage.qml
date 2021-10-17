import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: recommendationPage

    property int currentPage: 1
    property int currentIndex: -1

    property bool isNewModel: true

    function addRecommendedWork(resp_j) {

        requestLock = false;

        if (!resp_j) return;

        var works = resp_j['illusts'];
        if (debugOn) console.log('found works:', works.length);

        if (debugOn) console.log('adding works to recommendationModel');
        for (var i in works) {

            var imgUrls = Prxrv.getImgUrls(works[i])

            var authorIcon50 = works[i]['user']['profile_image_urls']['px_50x50'];
            var authorIconM = works[i]['user']['profile_image_urls']['medium'];
            if (!authorIcon50 && authorIconM)
                authorIcon50 = authorIconM.replace('_170.', '_50.');

            recommendationModel.append({
                workID: works[i]['id'],
                title: works[i]['title'],
                headerText: works[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: authorIcon50,
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                authorAccount: works[i]['user']['account'],
                isManga: works[i]['is_manga'] || false,
                isBookmarked: works[i]['is_bookmarked'],
            });
        }
    }

    function getWork() {
        Pixiv.getRecommendation(token, currentPage, addRecommendedWork);
    }


    Component {
        id: recommendationDelegate

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

        model: recommendationModel
        delegate: recommendationDelegate

        header: PageHeader {
            title: qsTr("Recommendation")
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        recommendationModel.clear()
                        currentPage = 1
                        getWork()
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !recommendationModel.count
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && recommendationModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    getWork()
                }
            }
        }

    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(recommendationModel)
            isNewModel = false
        }
        if (recommendationModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                getWork()
            } else {
                // Try again
            }
        }
    }

}
