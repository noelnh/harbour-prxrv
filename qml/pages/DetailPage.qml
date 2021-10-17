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
    property bool isBookmarked: false
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

    function toggleIcon(resp) {
        if (resp['is_bookmarked']) {
            Prxrv.toggleIconOn()
        } else {
            Prxrv.toggleIconOff()
        }
    }

    function setBookmarkOn() {
        // bookmark added
        if (debugOn) console.log("Bookmark Done")
        favCount += 1
        isBookmarked = true
        bookmarkIcon.source = '../images/button-bookmark-active.svg'
        bookmarkAction.text = qsTr("Remove bookmark")
        bookmarkLable.text = " +" + favCount
        Prxrv.toggleIconOn()

        if (fromID == workID) {
            if (debugOn) console.log("set refreshWorkDetails true")
            refreshWorkDetails = true
        }
    }

    function setBookmarkOff() {
        // bookmark removed
        if (debugOn) console.log("Bookmark removed")
        favCount -= 1
        isBookmarked = false
        bookmarkIcon.source = '../images/button-bookmark.svg'
        bookmarkAction.text = qsTr("Bookmark")
        bookmarkLable.text = " +" + favCount
        Prxrv.toggleIconOff()

        if (fromID == workID) {
            if (debugOn) console.log("set refreshWorkDetails true")
            refreshWorkDetails = true
        }
    }

    function updateBookmark(resp_j) {
        // TODO add tags
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

        var resp = resp_j['illust']

        if (debugOn) console.log('authorID', authorID)
        authorID = authorID || resp['user']['id']

        isBookmarked = resp['is_bookmarked']
        if (resp['is_bookmarked']) {
            bookmarkIcon.source = '../images/button-bookmark-active.svg'
            bookmarkAction.text = qsTr("Remove bookmark")
        }
        favCount = resp['total_bookmarks']
        bookmarkLable.text = " +" + favCount

        rateLabel.text = " " + resp['total_view']

        commentLable.text = " +" + resp['total_comments']

        caption.text = resp['caption']
        updateTime.text = Prxrv.getLocalDatetime(resp['create_date'])

        var tags = resp['tags']
        tagModel.clear()
        for (var i in tags) {
            tagModel.append( { tag: tags[i]['name'] } )
        }

        /*
         if (refreshWorkDetails && fromID == "-1") {
             if (debugOn) console.log("toggle icon after refreshWorkDetails")
             refreshWorkDetails = false
         }
         */
        if (currentIndex >= 0) {
            toggleIcon(resp)
        }

        if (currentIndex < 0) {
            var imgUrls = Prxrv.getImgUrls(resp)
            work = {
                'headerText': resp['title'],
                'title': resp['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                'authorIcon': resp['user']['profile_image_urls']['medium'],
                'authorAccount': resp['user']['account'],
                'authorName': resp['user']['name']
            }
        }

        if (resp['page_count'] > 1) {
            pageCount = resp['page_count'] || 1
            var p0 = work.master480
            for (var i = 0; i < pageCount; i++) {
                var pn = '_p' + i + '_'
                slideModel.append( { imgUrl: p0.replace('_p0_', pn) } )
            }
        }
    }

    function download(pageIndex) {
        // %a: authorID, %u: work.authorAccount, %n: work.authorName, %i: workID, %t: work.title
        if (debugOn) console.log('custom filename', '%a:', authorID, '%u:', work.authorAccount, '%n:', work.authorName,
                                 '%i:', workID, '%t:', work.title)
        var _filename = customName.replace('%a', authorID).replace('%u', work.authorAccount).replace('%n', work.authorName)
        var filename = _filename
        var pn, src_large, thumb
        for (var i = 0; i < pageCount; i++) {
            if ((pageIndex || pageIndex === 0) && pageIndex !== i) {
                continue
            }
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
            Pixiv.getBookmarkDetail(token, workID, updateBookmark)
        }
    }


    Component {
        id: morePage

        Page {
            SilicaListView {
                PullDownMenu {
                    MenuItem {
                        text: qsTr("Download all")
                        onClicked: download()
                    }
                }

                anchors.fill: parent

                header: PageHeader {
                    id: moreHeader
                    width: parent.width
                    title: work.headerText
                }

                model: slideModel

                delegate: ListItem {
                    width: parent.width
                    contentHeight: moreImage.height || Theme.itemSizeSmall
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
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Download")
                            onClicked: download(index)
                        }
                    }

                    onClicked: {
                        pageStack.push("PreviewPage.qml", {
                            url: imgUrl.replace(/\/.\/.*\/img-master/, '/img-master')
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
                text: qsTr("Related works")
                onClicked: pageStack.push("RelatedWorksPage.qml", { fromID: workID })
            }
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
                        if (isBookmarked) {
                            Pixiv.unbookmarkWork(token, workID, privBookmark)
                        } else {
                            privBookmark()
                        }
                    }
                }
            }
            MenuItem {
                id: bookmarkAction
                text: isBookmarked ? qsTr("Remove bookmark") : qsTr("Bookmark")
                onClicked: {
                    if (loginCheck()) {
                        if (isBookmarked) {
                            if (debugOn) console.log("Removing bookmark:", workID)
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

                Rectangle {
                    visible: pageCount > 1
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    width: parent.width
                    height: parent.width / 16
                    color: 'transparent'

                    Image {
                        id: pageCountImg
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: Theme.paddingSmall
                        anchors.leftMargin: Theme.paddingSmall
                        source: "../images/page-count.svg"
                        width: parent.height - Theme.paddingSmall * 2
                        height: width
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: Theme.paddingSmall / 2
                        anchors.left: pageCountImg.right
                        anchors.leftMargin: Theme.paddingSmall
                        text: pageCount
                        color: 'white'
                        font.bold: true
                    }
                }

                onClicked: {
                    if (slideModel.count > 0) {
                        pageStack.push(morePage)
                    } else {
                        pageStack.push("PreviewPage.qml", {
                            url: work.master480.replace(/\/.\/.*\/img-master/, '/img-master')
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
                    var isPxvLink = Prxrv.isPixivLink(link)
                    if (isPxvLink) {
                        if (isPxvLink[0]) {
                            var _props0 = {"workID": isPxvLink[1], "authorID": "", "currentIndex": -1}
                            pageStack.push("DetailPage.qml", _props0)
                        } else {
                            currentModel.push("userWorkModel")
                            var _props1 = {"authorName": "", "authorID": isPxvLink[1]}
                            pageStack.push("UserWorkPage.qml", _props1)
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
                    source: '../images/button-view.svg'
                    anchors.verticalCenter: parent.verticalCenter
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
                    anchors.verticalCenter: parent.verticalCenter
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
                    anchors.verticalCenter: parent.verticalCenter
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

