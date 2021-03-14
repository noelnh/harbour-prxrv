import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: relatedWorksPage

    property int currentPage: 1
    property int currentIndex: -1
    property string fromID: ''

    property bool isEmpty: false
    property bool isNewModel: true
    property var workIds: ({})
    property var seedIds: []

    ListModel { id: relatedWorksModel }

    function addRelatedWorks(resp_j) {

        requestLock = false;

        if (!resp_j) {
            isEmpty = true
            if (currentPage > 0) {
                currentPage -= 1;
            }
            return;
        };

        var works = resp_j['illusts'];
        if (debugOn) console.log('found works:', works.length);
        isEmpty = !works.length

        if (debugOn) console.log('adding works to relatedWorksModel');
        for (var i in works) {
            var workId = works[i]['id']
            if (workId in workIds) {
                if (debugOn) console.log('duplicate id:', workId)
                continue
            }
            workIds[workId] = true

            var imgUrls = Prxrv.getImgUrls(works[i])

            var authorIcon50 = works[i]['user']['profile_image_urls']['px_50x50'];
            var authorIconM = works[i]['user']['profile_image_urls']['medium'];
            if (!authorIcon50 && authorIconM)
                authorIcon50 = authorIconM.replace('_170.', '_50.');

            relatedWorksModel.append({
                workID: workId,
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
                favoriteID: works[i]['favorite_id'] || 0
            });
        }
    }

    function getWork() {
        if (!isEmpty) {
            var _seedIds = seedIds[0] ? seedIds.slice(0, 3) : seedIds.slice(1, 4)
            if (debugOn) console.log('seed IDs:', JSON.stringify(_seedIds))
            Pixiv.getRelatedWorks(token, fromID, _seedIds, currentPage, addRelatedWorks);
        } else {
            requestLock = false
            if (debugOn) console.log('No more works', isEmpty)
            showErrorMessage(qsTr("No more works"))
        }
    }


    Component {
        id: relatedWorksDelegate

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
                            if (!favoriteID) {
                                seedIds.splice(0, 0, workID)
                            }
                            Prxrv.toggleBookmarkIcon(workID, favoriteID)
                        }
                    }
                }
            }

            onClicked: {
                var _props = {"workID": workID, "authorID": authorID, "currentIndex": index}
                if (seedIds.length) {
                    seedIds.splice(1, 0, workID)
                } else {
                    seedIds.splice(0, 0, 0, workID)
                }
                currentPage = 0
                isEmpty = false
                pageStack.push("DetailPage.qml", _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: relatedWorksModel
        delegate: relatedWorksDelegate

        header: PageHeader {
            title: qsTr("Related Works")
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        relatedWorksModel.clear()
                        workIds = {}
                        seedIds = []
                        currentPage = 1
                        isEmpty = false
                        getWork()
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: (requestLock || !relatedWorksModel.count) && !isEmpty
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && relatedWorksModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    getWork()
                }
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (currentModel[currentModel.length-1] == "relatedWorksModel") {
                    worksModelStack.pop()
                    currentModel.pop()
                    if (debugOn) console.log("pop model: relatedWorksModel")
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            currentModel.push("relatedWorksModel")
            worksModelStack.push(relatedWorksModel)
            isNewModel = false
        }
        if (relatedWorksModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                getWork()
            } else {
                // Try again
            }
        }
    }
}
