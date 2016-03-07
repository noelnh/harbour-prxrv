import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/booru.js" as Booru
import "../js/prxrv.js" as Prxrv

Page {
    id: booruPage

    property int currentPage: 1
    property int currentIndex: -1

    ListModel { id: booruModel }


    // Add posts to this model
    function addBooruPosts(works) {

        requestLock = false;

        if (!works) return;

        if (debugOn) console.log('adding posts to booruModel')
        for (var i in works) {
            if (!showR18 && works[i]['rating'] !== 's') continue;
            booruModel.append( {
                workID: works[i]['id'],
                headerText: works[i]['id'],
                preview: works[i]['preview_url'],
                sample: works[i]['sample_url'],
                large: works[i]['file_url'],
                source: works[i]['source'],
                authorID: works[i]['creator_id'],
                authorName: works[i]['author'],
                md5: works[i]['md5'],
                tags: works[i]['tags'],
                createdAt: works[i]['created_at']
            } )
        }
    }
    Component {
        id: booruDelegate

        BackgroundItem {
            width: gridView.cellWidth
            height: width

            Image {
                anchors.centerIn: parent
                width: gridView.cellWidth
                height: width
                fillMode: Image.PreserveAspectCrop
                source: preview
            }

            onClicked: {
                var _props = {"workID": workID, "currentIndex": index, "work": booruModel.get(index)}
                pageStack.push("BooruDetailPage.qml", _props)
            }
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 2
        cellHeight: cellWidth

        model: booruModel
        delegate: booruDelegate

        header: PageHeader {
            title: "Yande.re"
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    booruModel.clear()
                    currentPage = 1
                    Booru.getPosts(50, currentPage, '', addBooruPosts)
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !booruModel.count
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (gridView.atYEnd) {
                console.log('gridView at end')
                if ( !requestLock && booruModel.count > 0 ) {
                    requestLock = true
                    currentPage += 1
                    Booru.getPosts(50, currentPage, '', addBooruPosts)
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                console.log("navigated back")
            }
        }
    }

    Component.onCompleted: {
        console.log("onCompleted")
       if (booruModel.count === 0) {
           currentPage = 1
           Booru.getPosts(50, currentPage, '', addBooruPosts)
       }
    }
}

