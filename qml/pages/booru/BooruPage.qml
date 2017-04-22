import QtQuick 2.2
import Sailfish.Silica 1.0

import "../../js/booru.js" as Booru
import "../../js/prxrv.js" as Prxrv

Page {
    id: booruPage

    property int currentPage: 1
    property int currentIndex: -1
    property int pageSize: 100

    property string searchTags: ''

    property string fromBooruId: ''

    property int emptyFetch: 0

    property bool pxvOnly: false
    property bool pxvDetail: true

    // TODO other sites
    property string booruSite: 'Yande.re'

    property int heightL: 0
    property int heightR: 0

    ListModel { id: booruModelL }
    ListModel { id: booruModelR }


    function generataPageStr() {
        return booruSite + "," + pageSize + "," + currentPage + "," + searchTags;
    }

    function reloadPostList(pageNum, _pxvOnly) {
        currentPage = pageNum || currentPage;
        if (typeof _pxvOnly === "boolean" && _pxvOnly !== pxvOnly) {
            pxvOnly = _pxvOnly;
        }
        booruModelL.clear();
        booruModelR.clear();
        emptyFetch = 0;
        Booru.getPosts(pageSize, currentPage, searchTags, addBooruPosts);
    }

    // Add posts to this model
    function addBooruPosts(works) {

        requestLock = false;

        if (!works) return;

        if (debugOn) console.log('adding posts to booruModel')
        var validCount = 0;
        for (var i in works) {
            if (!showR18 && works[i]['rating'] !== 's') continue;
            if (pxvOnly && !isPxvSource(works[i]['source'], true)) continue;
            // TODO pxv icon
            var elmt = {
                workID: works[i]['id'],
                parentID: works[i]['parent_id'],
                hasChildren: works[i]['has_children'],
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
//                if (debugOn) console.log('left +', 270 * elmt.height_p);
            } else {
                elmt.column = 'R';
                booruModelR.append(elmt);
                heightR += elmt.height_p * 100;
//                if (debugOn) console.log('right +', 270 * elmt.height_p);
            }
            validCount += 1;
        }
        if (emptyFetch < 2) {
            if (validCount === 0) {
                emptyFetch += 1;
                requestLock = true;
                currentPage += 1;
                Booru.getPosts(pageSize, currentPage, searchTags, addBooruPosts);
            } else {
                emptyFetch = 0;
            }
        } else {
            infoBanner.showText("Cannot load posts...");
        }
    }

    function isPxvSource(url, shortMatch) {
        var _url = url;
        if (typeof url !== "string") _url = url.toString();
        if (shortMatch) return _url.indexOf('pixiv') > 0 || _url.indexOf('pximg') > 0;
        return _url.indexOf('pixiv.net/img-orig') > 0 || _url.indexOf('pximg.net/img-orig') > 0;
    }


    Component {
        id: booruDelegate

        ListItem {
            id: bitem
            width: parent.width
            contentHeight: width * height_p

            property var postSrc: source

            Image {
                id: image
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: preview

                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: isPxvSource(postSrc, true) ? "https://source.pixiv.net/touch/touch/img/cmn/favicon.ico" : ""
                }
            }

            onClicked: {
                if (pxvDetail && isPxvSource(source, true)) {
                    var illust_id = 'None'
                    if (source.indexOf('illust_id=') > 0) {
                        illust_id = source.substr(source.indexOf('illust_id=')+10)
                    } else if (isPxvSource(source)) {
                        var illust_name = source.substr(source.lastIndexOf('/')+1)
                        illust_id = illust_name.substr(0, illust_name.indexOf('_'))
                    }
                    if (!isNaN(illust_id) && illust_id > 0) {
                        var _props = {"workID": illust_id, "authorID": "", "currentIndex": -1}
                        pageStack.push("../DetailPage.qml", _props)
                    }
                } else {
                    if (fromBooruId == workID) { // string == number
                        pageStack.pop()
                    } else {
                        var _props = {
                            "workID": workID,
                            "currentIndex": index,
                            "fromTags": searchTags,
                            "pxvOnly": pxvOnly,
                            "booruSite": booruSite,
                            "work": column === 'L' ? booruModelL.get(index) : booruModelR.get(index)
                        }
                        pageStack.push("BooruDetailPage.qml", _props)
                    }
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
            title: booruSite + ": " + searchTags + " P" + currentPage
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: reloadPostList()
            }
            MenuItem {
                text: qsTr("Previous page")
                visible: currentPage > 1
                onClicked: {
                    if (!requestLock) {
                        requestLock = true;
                        reloadPostList(currentPage - 1);
                    }
                }
            }
        }

        PushUpMenu {
            id: pushUpMenu
            MenuItem {
                text: qsTr("Next page")
                onClicked: {
                    if (!requestLock) {
                        requestLock = true;
                        reloadPostList(currentPage + 1);
                    }
                }
            }
            MenuItem {
                text: qsTr("Go to page ...")
                onClicked: {
                    pageStack.navigateForward();
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
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            pageStack.pushAttached("OptionsDialog.qml", {
                                       "_currentPage": currentPage,
                                       "_pxvOnly": pxvOnly,
                                       "_pxvDetail": pxvDetail,
                                       "_tags": searchTags
                                   });
        }
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                console.log("navigated back")
            }
        }
    }

    Component.onCompleted: {
       if (booruModelR.count + booruModelL.count === 0) {
           currentPage = 1
           Booru.getPosts(pageSize, currentPage, searchTags, addBooruPosts)
       }
    }
}

