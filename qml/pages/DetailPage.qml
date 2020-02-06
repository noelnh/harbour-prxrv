import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: detailPage

    property string workID: ''
    property string authorID: ''

    property var work: {}
    property int pageCount: 1

    property int currentIndex: -1
    property int favoriteID: 0
    property string fromID: '-1'
    property string fromTag: ''

    property int favCount: 0

    property bool isEmptyPage: false


    ListModel { id: slideModel }
    ListModel { id: tagModel }


    function privBookmark() {
        if (debugOn) console.log("Bookmark privately")
        Pixiv.bookmarkWork(token, workID, 'private', setBookmarkOn)
    }

    function toggleIcon(resp_j) {
        if (resp_j['count'] && resp_j['response'][0]['favorite_id']) {
            Prxrv.toggleIconOn()
        } else {
            Prxrv.toggleIconOff()
        }
    }

    function setBookmarkOn() {
        // bookmark added
        if (debugOn) console.log("Bookmark Done")
        favoriteID = 1
        bookmarkIcon.source = '../images/button-bookmark-active.svg'
        bookmarkAction.text = "Remove bookmark"
        bookmarkLable.text = " +" + (favCount + 1)
        Prxrv.toggleIconOn()

        if (fromID == workID) {
            if (debugOn) console.log("set refreshWorkDetails true")
            refreshWorkDetails = true
        }
    }

    function setBookmarkOff() {
        // bookmark removed
        if (debugOn) console.log("Bookmark removed")
        favoriteID = 0
        bookmarkIcon.source = '../images/button-bookmark.svg'
        bookmarkAction.text = "Bookmark"
        bookmarkLable.text = " +" + (favCount - 1)
        Prxrv.toggleIconOff()

        if (fromID == workID) {
            if (debugOn) console.log("set refreshWorkDetails true")
            refreshWorkDetails = true
        }
    }

    function setDetails(resp_j) {

        if (!resp_j) {
            if (isEmptyPage) {
                pageStack.pop()
                isEmptyPage = false
            } else {
                isEmptyPage = true
            }
            return
        }

        var resp = resp_j['response']

        if (resp['count']) {
            return
        }

        if (debugOn) console.log('authorID', authorID)
        authorID = authorID || resp[0]['user']['id']

        if (debugOn) console.log("liked: " + resp[0]['is_liked'])
        if (debugOn) console.log("fav: " + resp[0]['favorite_id'])

        favoriteID = resp[0]['favorite_id']
        if (favoriteID > 0) {
            bookmarkIcon.source = '../images/button-bookmark-active.svg'
            bookmarkAction.text = "Remove bookmark"
        }
        var _counts = resp[0]['stats']['favorited_count']
        favCount = _counts['public'] + _counts['private']
        bookmarkLable.text = " +" + favCount

        if (resp[0]['is_liked']) {
            rateIcon.source = '../images/button-rate-active.svg'
        }
        rateLabel.text = " +" + resp[0]['stats']['scored_count']

        commentLable.text = " +" + resp[0]['stats']['commented_count']

        caption.text = resp[0]['caption']
        updateTime.text = resp[0]['reuploaded_time']

        var tags = resp[0]['tags']
        tagModel.clear()
        for (var i in tags) {
            tagModel.append( { tag: tags[i] } )
        }

        /*
         if (refreshWorkDetails && fromID == "-1") {
             if (debugOn) console.log("toggle icon after refreshWorkDetails")
             refreshWorkDetails = false
         }
         */
        if (currentIndex >= 0) {
            toggleIcon(resp_j)
        }

        if (currentIndex < 0) {
            work = {
                'headerText': resp[0]['title'],
                'title': resp[0]['title'],
                'master480': resp[0]['image_urls']['px_480mw'],
                'large': resp[0]['image_urls']['large'],
                'square128': resp[0]['image_urls']['px_128x128'],
                'authorIcon': resp[0]['user']['profile_image_urls']['px_50x50'],
                'authorAccount': resp[0]['user']['account'],
                'authorName': resp[0]['user']['name']
            }
        }

        if (!work.large) {
            work.large = resp[0]['image_urls']['large']
        }

        if (resp[0]['is_manga']) {
            pageCount = resp[0]['page_count'] || 1
            var p0 = work.master480
            for (var i = 0; i < pageCount; i++) {
                var pn = '_p' + i + '_'
                slideModel.append( { imgUrl: p0.replace('_p0_', pn) } )
            }
            // TODO pageStack.pushAttached(relatedPage)
        }
    }

    function download() {
        // %a: authorID, %u: work.authorAccount, %n: work.authorName, %i: workID, %t: work.title
        if (debugOn) console.log('custom filename', '%a:', authorID, '%u:', work.authorAccount, '%n:', work.authorName,
                                 '%i:', workID, '%t:', work.title)
        var _filename = customName.replace('%a', authorID).replace('%u', work.authorAccount).replace('%n', work.authorName)
        var filename = _filename
        var pn, src_large, thumb
        for (var i = 0; i < pageCount; i++) {
            pn = '_p' + i
            src_large = work.large.replace('_p0.', pn+'.')
            thumb = work.square128.replace('_p0_', pn+'_')

            // file name
            if (_filename.indexOf('%i') >= 0) {
                filename = _filename.replace('%i', workID + pn).replace('%t', work.title)
            } else if (_filename.indexOf('%t') >= 0) {
                filename = _filename.replace('%t', work.title + pn)
            } else {
                filename += workID + pn
            }
            filename += work.large.substr(work.large.lastIndexOf('.'))

            if (savePath[savePath.length-1] !== '/') savePath += '/'
            var _savePath = savePath
            // sub directory
            if (filename.lastIndexOf('/') > 0) {
                if (filename[0] === '/') filename = filename.substr(1)
                _savePath += filename.substr(0, filename.lastIndexOf('/')+1)
                filename = filename.substr(filename.lastIndexOf('/')+1)
            }

            if (debugOn) console.log("Downloading:", src_large, "to", _savePath, filename)
            requestMgr.saveImage(token, src_large, _savePath, filename, 0)
            downloadsModel.append( {
                          filename: filename,
                          path: _savePath,
                          source: src_large,
                          thumb: thumb,
                          finished: 0
                      } )
        }
    }

    function loadDetails() {
        if (debugOn) console.log("Loading details")
        if (loginCheck()) {
            if (debugOn) console.log('work id: ' + workID)
            Pixiv.getWorkDetails(token, workID, setDetails)
        }
    }


    Component {
        id: morePage

        Page {
            SilicaListView {
                anchors.fill: parent

                header: PageHeader {
                    id: moreHeader
                    width: parent.width
                    title: work.headerText
                }

                model: slideModel

                delegate: BackgroundItem {
                    width: parent.width
                    height: moreImage.height
                    Separator {
                        id: sepLine
                        width: parent.width
                        color: Theme.secondaryColor
                    }
                    Label {
                        anchors.left: parent.left
                        anchors.top: sepLine.bottom
                        text: index
                    }
                    Image {
                        id: moreImage
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: imgUrl
                    }
                    onClicked: {
                        pageStack.push("PreviewPage.qml", {
                            url: imgUrl.replace(/\/.\/480x960/, '')
                        })
                    }
                }
            }
        }
    }

    SilicaFlickable {
        id: detailFlickable
        contentHeight: column.height + 200

        anchors.fill: parent

        PageHeader {
            id: pageHeader
            width: parent.width
            title: work.headerText
        }

        PushUpMenu {
            id: pushUpMenu
            MenuItem {
                id: openWebViewAction
                text: qsTr("Open Web Page")
                onClicked: {
                    refreshWorkDetails = true
                    var _props = {"initUrl": "http://touch.pixiv.net/member_illust.php?mode=medium&illust_id=" + workID }
                    pageStack.push('WebViewPage.qml', _props)
                }
            }
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: refreshAction
                text: qsTr("Refresh")
                onClicked: loadDetails()
            }
            MenuItem {
                id: downloadAction
                text: qsTr("Download")
                onClicked: download()
            }

            MenuItem {
                id: privBookmarkAction
                text: qsTr("Bookmark privately")
                onClicked: {
                    if (loginCheck()) {
                        if (favoriteID > 0) {
                            Pixiv.unbookmarkWork(token, favoriteID, privBookmark)
                        } else {
                            privBookmark()
                        }
                    }
                }
            }
            MenuItem {
                id: bookmarkAction
                text: favoriteID > 0 ? qsTr("Remove bookmark") : qsTr("Bookmark")
                onClicked: {
                    if (loginCheck()) {
                        if (favoriteID > 0) {
                            if (debugOn) console.log("Removing bookmark:", favoriteID, workID)
                            Pixiv.unbookmarkWork(token, workID, setBookmarkOff)
                        } else {
                            if (debugOn) console.log("Adding bookmark:", workID)
                            Pixiv.bookmarkWork(token, workID, 'public', setBookmarkOn)
                        }
                    }
                }
            }
        }

        Item {
            id: column
            width: parent.width
            height: childrenRect.height
            anchors.top: pageHeader.bottom

            BackgroundItem {
                id: imageItem
                width: parent.width
                height: image.height || Theme.itemSizeSmall
                Image {
                    id: image
                    anchors.horizontalCenter: parent.horizontalCenter

                    source: work.master480

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: image.status === Image.Loading
                    }

                }
                onClicked: {
                    if (slideModel.count > 0) {
                        pageStack.push(morePage)
                    } else {
                        pageStack.push("PreviewPage.qml", {
                            url: work.master480.replace(/\/.\/480x960/, '')
                        })
                    }
                }
            }

            Item {
                id: authorBar
                width: parent.width - Theme.paddingLarge * 2
                height: Theme.fontSizeMedium * 2.5
                anchors.top: imageItem.bottom
                anchors.topMargin: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    id: authorIcon
                    width: Theme.fontSizeMedium * 2.5
                    height: width
                    anchors.top: parent.top
                    anchors.left: parent.left
                    source: work.authorIcon
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (currentModel[currentModel.length-1] === "userWorkModel") {
                                if (debugOn) console.log('nav back to user work page ' + authorID)
                                pageStack.navigateBack()
                            } else {
                                if (debugOn) console.log('push user work page ' + authorID)
                                currentModel.push("userWorkModel")
                                var _props = {"authorName": authorName.text, "authorID": authorID, "fromID": workID}
                                pageStack.push("UserWorkPage.qml", _props)
                                coverIndex[0] = 0
                            }
                        }
                    }
                }
                Column {
                    width: parent.width - authorIcon.width - Theme.paddingMedium
                    height: Theme.fontSizeMedium * 2.5
                    anchors.top: parent.top
                    anchors.left: authorIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        text: work.title
                        elide: TruncationMode.Elide
                    }
                    Label {
                        id: authorName
                        width: parent.width
                        color: Theme.secondaryColor
                        text: work.authorName
                        elide: TruncationMode.Elide
                    }
                }
            }

            Label {
                id: caption
                width: parent.width - Theme.paddingLarge * 2
                anchors.top: authorBar.bottom
                anchors.topMargin: Theme.paddingMedium
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                wrapMode: Text.WordWrap
                onLinkActivated: {
                    if (link.indexOf('/member.php?id=') > 0) {
                        var member_id = link.substring(link.indexOf('id=') + 3)
                        if (!isNaN(member_id)) {
                            currentModel.push("userWorkModel")
                            var _props = {"authorName": "", "authorID": member_id}
                            pageStack.push("UserWorkPage.qml", _props)
                        }
                    } else if (link.indexOf('illust_id=') > 0) {
                        var illust_id = link.substring(link.indexOf('_id=') + 4)
                        if (!isNaN(illust_id)) {
                            var _props = {"workID": illust_id, "authorID": "", "currentIndex": -1}
                            pageStack.push("DetailPage.qml", _props)
                        }
                    } else {
                        Qt.openUrlExternally(link)
                    }
                }
                color: Theme.primaryColor
                text: ""
            }

            Label {
                id: updateTime
                width: parent.width - Theme.paddingLarge * 2
                anchors.top: caption.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignRight
                color: Theme.secondaryColor
                text: ""
            }

            ListView {
                anchors.top: updateTime.bottom
                anchors.topMargin: 10
                width: parent.width
                height: childrenRect.height + Theme.itemSizeSmall

                model: tagModel
                delegate: ListItem {
                    width: parent.width
                    height: Theme.itemSizeSmall
                    Label {
                        width: parent.width - Theme.paddingLarge * 2
                        anchors.centerIn: parent
                        color: Theme.secondaryHighlightColor
                        text: tag
                    }
                    onClicked: {
                        if (tag === fromTag) {
                            if (debugOn) console.log('pop back to same tag')
                            pageStack.pop()
                        } else {
                            var params = {
                                'q': tag,
                                'mode': 'tag',
                                'period': 'all',
                                'sort': 'popular',
                                'order': 'desc',
                            }
                            if (debugOn) console.log('push search model')
                            currentModel.push("worksSearchModel")
                            pageStack.push("WorksSearchPage.qml", { searchParams: params, fromTag: tag })
                            coverIndex[0] = 0
                        }
                    }
                }
            }
        }

        onVerticalVelocityChanged: {
            if (verticalVelocity > 0) {
                panel.open = false
            } else if (verticalVelocity < 0) {
                panel.open = true
            }
            if (detailFlickable.atYEnd) {
                panel.open = true
            }
        }

        onAtYEndChanged: {
            if (detailFlickable.atYEnd) {
                panel.open = true
            }
        }
    }

    DockedPanel {
        id: panel

        width: parent.width
        height: Theme.itemSizeSmall

        dock: Dock.Bottom
        open: true

        Row {
            anchors.centerIn: parent
            width: parent.width

            Row {
                width: parent.width / 3
                Item {
                    height: parent.height
                    width: Theme.paddingMedium
                }
                Image {
                    id: rateIcon
                    source: '../images/button-rate.svg'
                }
                Label {
                    id: rateLabel
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: ''
                }
            }
            Row {
                width: parent.width / 3
                Item {
                    height: parent.height
                    width: Theme.paddingMedium
                }
                Image {
                    id: bookmarkIcon
                    source: '../images/button-bookmark.svg'
                }
                Label {
                    id: bookmarkLable
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: ''
                }
            }
            Row {
                width: parent.width / 3
                Item {
                    height: parent.height
                    width: Theme.paddingMedium
                }
                Image {
                    id: commentIcon
                    source: '../images/button-comment.svg'
                }
                Label {
                    id: commentLable
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: ''
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (debugOn) console.log("detail page actived: " + workID)
            if (fromID == "-1" && refreshWorkDetails && loginCheck()) {
                if (debugOn) console.log("refresh work details")
                loadDetails()
                refreshWorkDetails = false
            }
            if (isEmptyPage) {
                pageStack.pop()
                isEmptyPage = false
            }
        }

        // Cover image index
        if (status == PageStatus.Activating) {
            // here _navigation is PageNavigation.None,
            // workaround is in Component.onCompleted
            //if (_navigation == PageNavigation.Forward) {
            //    coverIndex[coverIndex.length] = currentIndex
            //}
            coverIndex[0] = coverIndex[coverIndex.length - 1]
        }
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                coverIndex.pop()
            } else {
                // _navigation is PageNavigation.None
                if (debugOn) console.log("Page nav forward", _navigation)
                //coverIndex[0] = 0 // Moved to function onClicked of each tag & authorIcon
            }
        }
    }

    Component.onCompleted: {
        if (debugOn) console.log("details onCompleted")

        if (authorID && currentIndex >= 0) {
            work = Prxrv.getModelItem(currentIndex)
        } else {
            work = {
                'headerText': '',
                'title': '',
                'master480': '',
                'large': '',
                'square128': '',
                'authorIcon': '',
                'authorAccount': '',
                'authorName': ''
            }
        }

        if (workID && loginCheck()) {
            loadDetails()
        } else {
            console.error("failed to load details")
        }

        // Cover image index
        coverIndex[coverIndex.length] = currentIndex
        coverIndex[0] = coverIndex[coverIndex.length - 1]
    }
}

