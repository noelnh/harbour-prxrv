import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/booru.js" as Booru
import "../js/prxrv.js" as Prxrv

Page {
    id: booruPage

    property int currentPage: 1
    property int currentIndex: -1

    // TODO store
    property bool pxvOnly: true

    // TODO other sites
    property string booruSite: 'Yande.re'

    property int heightL: 0
    property int heightR: 0

    ListModel { id: booruModelL }
    ListModel { id: booruModelR }


    // Add posts to this model
    function addBooruPosts(works) {

        requestLock = false;

        if (!works) return;

        if (debugOn) console.log('adding posts to booruModel')
        for (var i in works) {
            if (!showR18 && works[i]['rating'] !== 's') continue;
            if (pxvOnly && works[i]['source'].indexOf('pixiv') < 0) continue;
            // TODO pxv icon
            var elmt = {
                workID: works[i]['id'],
                headerText: booruSite + ' ' + works[i]['id'],
                preview: works[i]['preview_url'],
                sample: works[i]['sample_url'],
                large: works[i]['file_url'],
                source: works[i]['source'],
                height_p: works[i]['actual_preview_height'] / works[i]['actual_preview_width'],
                authorID: works[i]['creator_id'],
                authorName: works[i]['author'],
                md5: works[i]['md5'],
                tags: works[i]['tags'],
                createdAt: works[i]['created_at']
            };
            if ( heightR >= heightL ) {
                elmt.column = 'L';
                booruModelL.append(elmt);
                heightL += elmt.height_p * 100;
                if (debugOn) console.log('left +', 270 * elmt.height_p);
            } else {
                elmt.column = 'R';
                booruModelR.append(elmt);
                heightR += elmt.height_p * 100;
                if (debugOn) console.log('right +', 270 * elmt.height_p);
            }
        }
    }


    Component {
        id: booruDelegate

        ListItem {
            id: bitem
            width: parent.width
            contentHeight: width * height_p

            Image {
                id: image
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: preview
            }

            onClicked: {
                if (source.indexOf('pixiv') > 0) {
                    var illust_id = 'None'
                    if (source.indexOf('illust_id=') > 0) {
                        illust_id = source.substr(source.indexOf('illust_id=')+10)
                    } else if (source.indexOf('pixiv.net/img-orig') > 0) {
                        var illust_name = source.substr(source.lastIndexOf('/')+1)
                        illust_id = illust_name.substr(0, illust_name.indexOf('_'))
                    }
                    if (!isNaN(illust_id) && illust_id > 0) {
                        var _props = {"workID": illust_id, "authorID": "", "currentIndex": -1}
                        pageStack.push("DetailPage.qml", _props)
                    }
                } else {
                    console.log('Column:', column)
                    var _props = {
                        "workID": workID,
                        "currentIndex": index,
                        "work": column === 'L' ? booruModelL.get(index) : booruModelR.get(index)
                    }
                    pageStack.push("BooruDetailPage.qml", _props)
                }
            }
        }
    }

    SilicaFlickable {
        id: booruFlicableView

        contentHeight: header.height + (columnLeft.height > columnRight.height ? columnLeft.height : columnRight.height)
        anchors.fill: parent

        PageHeader {
            id: header
            title: booruSite
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    booruModelL.clear()
                    booruModelR.clear()
                    currentPage = 1
                    Booru.getPosts(50, currentPage, '', addBooruPosts)
                }
            }
            MenuItem {
                text: pxvOnly ? qsTr("Show all") : qsTr("Show pixiv only")
                onClicked: {
                    pxvOnly = !pxvOnly
                    booruModelL.clear()
                    booruModelR.clear()
                    currentPage = 1
                    Booru.getPosts(50, currentPage, '', addBooruPosts)
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !(booruModelL.count + booruModelR.count)
        }

        ListView {
            id: columnLeft
            width: parent.width / 2
            height: childrenRect.height
            anchors.top: header.bottom
            anchors.left: parent.left

            model: booruModelL
            delegate: booruDelegate

        }

        ListView {
            id: columnRight
            width: parent.width / 2
            height: childrenRect.height
            anchors.top: header.bottom
            anchors.left: columnLeft.right

            model: booruModelR
            delegate: booruDelegate

        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (booruFlicableView.atYEnd) {
                console.log('gridView at end')
                if ( !requestLock && booruModelL.count + booruModelR.count > 0 ) {
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
       if (booruModelR.count + booruModelL.count === 0) {
           currentPage = 1
           Booru.getPosts(50, currentPage, '', addBooruPosts)
       }
    }
}

