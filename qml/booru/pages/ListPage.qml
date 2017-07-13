import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/booru.js" as Booru
import "../js/sites.js" as Sites
import "../js/utils.js" as Utils
import "../js/accounts.js" as Accounts

Page {
    id: listPage

    property int currentPage: 1
    property int currentIndex: -1
    property int pageSize: 40

    property string searchTags: ''

    property string fromBooruId: ''

    property int emptyFetch: 0
    property int maxEmptyFetch: 3

    property string domain: ''
    property string siteName: '?'
    property string username: ''

    property int heightL: 0
    property int heightR: 0

    ListModel { id: booruModelL }
    ListModel { id: booruModelR }


    function reloadPostList(pageNum, _tags) {
        currentPage = pageNum || currentPage;
        searchTags = _tags || searchTags;
        booruModelL.clear();
        booruModelR.clear();
        requestLock = true;
        Booru.getPosts(currentSite, pageSize, currentPage, searchTags, addBooruPosts);
    }

    function checkEmptyFetch() {
        if (emptyFetch < maxEmptyFetch) {
            emptyFetch += 1;
            currentPage += 1;
            reloadPostList();
        }
    }

    function checkProtocol(prot, work) {
        var urlNames = ['preview_url', 'sample_url', 'file_url'];
        var urls = {};
        for (var i in urlNames) {
            var name = urlNames[i];
            var url = work[name];
            urls[name] = url.indexOf('//') === 0 ? prot + url : url;
        }
        return urls;
    }

    // Add posts to this model
    function addBooruPosts(works) {

        requestLock = false;

        if (!works) return;

        if (debugOn) console.log('adding posts to booruModel')

        var prot = 'http:';
        if (currentSite && currentSite.indexOf('https:') === 0) {
            prot = 'https:';
        }

        var validCount = 0;
        for (var i in works) {
            if (!showR18 && works[i]['rating'] !== 's') continue;
            var urls = checkProtocol(prot, works[i]);
            var elmt = {
                workID: works[i]['id'],
                parentID: works[i]['parent_id'],
                hasChildren: works[i]['has_children'],
                headerText: siteName + ' ' + works[i]['id'],
                preview: urls['preview_url'],
                sample: urls['sample_url'],
                large: urls['file_url'],
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
                //if (debugOn) console.log('left +', 270 * elmt.height_p);
            } else {
                elmt.column = 'R';
                booruModelR.append(elmt);
                heightR += elmt.height_p * 100;
                //if (debugOn) console.log('right +', 270 * elmt.height_p);
            }
            validCount += 1;
        }

        if (validCount === 0) {
            checkEmptyFetch();
        } else {
            emptyFetch = 0;
        }
    }

    function isPxvSource(source) {
        return 'pixiv' === Utils.checkSourceSite(currentSite, source, 'name');
    }

    function parsePxvID(source) {
        var illust_id = 'None'
        if (source.indexOf('illust_id=') > 0) {
            illust_id = source.substr(source.indexOf('illust_id=')+10)
        } else {
            var illust_name = source.substr(source.lastIndexOf('/')+1)
            var pa = illust_name.indexOf('_');
            var pb = illust_name.indexOf('.');
            if (pa > 0) {
                illust_id = illust_name.substr(0, pa);
            } else if (pb > 0) {
                illust_id = illust_name.substr(0, pb);
            }
        }
        if (!isNaN(illust_id) && illust_id > 0)
            return illust_id;
        else
            return -1;
    }


    Component {
        id: booruDelegate

        ListItem {
            id: bitem
            width: parent.width
            contentHeight: width * height_p

            property var postSrc: source

            menu: ContextMenu {
                anchors.right: parent ? parent.right : undefined    // ContextMenu's parent: null -> ListItem
                MenuItem {
                    visible: currentUsername
                    text: qsTr("Like")
                    onClicked: {
                        console.log("Like post:", workID);
                        Booru.vote(currentSite, currentUsername, currentPasshash, workID, 3, function(resp) {});
                    }
                }
                MenuItem {
                    visible: currentUsername
                    text: qsTr("Unlike")
                    onClicked: {
                        console.log("Unlike post:", workID);
                        Booru.vote(currentSite, currentUsername, currentPasshash, workID, 2, function(resp) {});
                    }
                }
            }

            Image {
                id: image
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: loadSample && height_p > 2 && sample ? sample : preview

                Image {
                    property string icon: Utils.checkSourceSite(currentSite, postSrc, 'icon')

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 18
                    height: 18
                    visible: icon
                    source: "../images/src.d120.png"

                    Image {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 16
                        height: 16
                        source: parent.icon
                    }
                }

            }

            onClicked: {
                currentThumb = preview
                var pillust_id = -1;
                if (openPxvDetails && isPxvSource(postSrc)) {
                    pillust_id = parsePxvID(postSrc);
                }
                var _props = {}
                if (pillust_id > 0) {
                    _props = {"workID": pillust_id, "authorID": "", "currentIndex": -1}
                    pageStack.push("../../pages/DetailPage.qml", _props)
                } else if (fromBooruId == workID) { // string == number
                    pageStack.pop()
                } else {
                    _props = {
                        "workID": workID,
                        "currentIndex": index,
                        "fromTags": searchTags,
                        "siteName": siteName,
                        "work": column === 'L' ? booruModelL.get(index) : booruModelR.get(index)
                    }
                    pageStack.push("PostPage.qml", _props)
                }
            }
        }
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: requestLock || (!(booruModelL.count + booruModelR.count) && emptyFetch < maxEmptyFetch)
    }

    Label {
        width: parent.width
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        visible: emptyFetch >= maxEmptyFetch && booruModelL.count + booruModelR.count === 0
        text: qsTr("No post here")
    }

    SilicaFlickable {
        id: booruFlicableView

        contentHeight: header.height + (columnLeft.height > columnRight.height ? columnLeft.height : columnRight.height)
        anchors.fill: parent

        PageHeader {
            id: header
            title: siteName + ": " + searchTags + " P" + currentPage
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
                                       "_tags": searchTags,
                                       "_siteName": siteName
                                   });
        }
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (debugOn) console.log("navigated back")
            }
        }
    }

    Component.onCompleted: {
        if (domain) {
            var site = Sites.find(domain);
            if (site) {
                currentSite = site['url'];
                siteName = site['name'];
            }
        }
        if (username === '--anonymous--') {
            currentUsername = '';
            currentPasshash = '';
        } else if (username) {
            var user = Accounts.find(domain, username);
            if (user) {
                currentUsername = user['username'];
                currentPasshash = user['passhash'];
            }
        }

        if (booruModelR.count + booruModelL.count === 0) {
            currentPage = 1
            Booru.getPosts(currentSite, pageSize, currentPage, searchTags, addBooruPosts)
        }
    }
}
