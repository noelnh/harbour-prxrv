import QtQuick 2.2
import Sailfish.Silica 1.0

import "../../js/booru.js" as Booru
import "../../js/prxrv.js" as Prxrv

Page {
    id: detailPage

    property string workID: ''

    property var work: {}

    property string fromTags: ''
    property bool pxvOnly: false
    property string booruSite: 'Yande.re'

    property bool faved: false
    property string username: "username"

    property int currentIndex: -1

    property int leftPadding: 25

    ListModel { id: tagModel }
    ListModel { id: familyModel }


    function findMe(resp) {
        var favedUsers = resp['favorited_users'];
        if (favedUsers) {
            if (favedUsers.split(",").indexOf(username) >= 0) {
                faved = true;
            } else {
                faved = false;
            }
        }
    }

    function getFavedUsers() {
        Booru.listFavedUsers(workID, findMe);
    }

    function toggleVote() {
        var score = 3;
        if (faved) score = 2;

        Booru.vote(workID, score, function(resp) {
            if (score > 2)
                faved = true;
            else
                faved = false;
        });
    }

    SilicaFlickable {
        id: detailFlickable
        contentHeight: column.height + 200

        anchors.fill: parent

        PageHeader {
            id: pageHeader
            width: parent.width
            title: (faved ? "★ " : "☆ ") + work.headerText
        }

        PushUpMenu {
            id: pushUpMenu
            MenuItem {
                id: openWebViewAction
                text: qsTr("Open Web Page")
                onClicked: {
                    var postUrl = "https://yande.re/post/show/" + workID
//                    var _props = {"initUrl":  postUrl}
//                    pageStack.push('WebViewPage.qml', _props)
                    Qt.openUrlExternally(postUrl);
                }
            }
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: voteAction
                text: faved ? qsTr("Unlike") : qsTr("Like")
                onClicked: toggleVote()
            }
        }

        Item {
            id: column
            width: parent.width
            height: childrenRect.height
            anchors.top: pageHeader.bottom

            Image {
                id: image
                width: parent.width - leftPadding*2
                anchors.horizontalCenter: parent.horizontalCenter

                fillMode: Image.PreserveAspectFit
                source: work.sample

                BusyIndicator {
                    anchors.centerIn: parent
                    running: image.status == Image.Loading
                }
            }

            Label {
                id: authorName
                width: parent.width - leftPadding*2
                anchors.top: image.bottom
                anchors.topMargin: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryColor
                text: qsTr("Uploaded by: ") + work.authorName
                elide: TruncationMode.Elide
            }

            Label {
                id: caption
                width: parent.width - leftPadding*2
                anchors.top: authorName.bottom
                anchors.topMargin: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                onLinkActivated: {
                    if (link.indexOf('illust_id=') > 0) {
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
                text: {
                    console.log('source:'+work.source+':')
                    if (work.source.indexOf('http') === 0 && work.source.indexOf('illust_id=') > 0) {
                        var illust_id = work.source.substr(work.source.indexOf('illust_id=')+10)
                        return 'Source: <a href="' + work.source + '">illust/' + illust_id + '</a>'
                    } else if (work.source.indexOf('pixiv.net/img-orig') > 0) {
                        var illust_name = work.source.substr(work.source.lastIndexOf('/')+1)
                        var illust_id = illust_name.substr(0, illust_name.indexOf('_'))
                        var pxv_url = 'http://touch.pixiv.net/member_illust.php?illust_id='+illust_id
                        return 'Source: <a href="' + pxv_url + '">illust/' + illust_id + '</a>'
                    } else if (work.source.indexOf('http') === 0) {
                        return 'Source: <a href="' + work.source + '">' + work.source + '</a>'
                    } else if (work.source !== '') {
                        return 'Source: ' + work.source
                    } else {
                        return ''
                    }
                }
            }

            Label {
                id: updateTime
                width: parent.width - leftPadding*2
                anchors.top: caption.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignRight
                color: Theme.secondaryColor
                text: {
                    var t = new Date(work.createdAt*1000)
                    return t.toISOString().replace('T',' ').substr(0,19)
                }
            }

            ListView {
                id: familyList
                anchors.top: updateTime.bottom
                anchors.topMargin: 10
                width: parent.width
                height: childrenRect.height

                model: familyModel
                delegate: ListItem {
                    height: Theme.itemSizeSmall
                    width: parent.width
                    Label {
                        width: parent.width
                        anchors {
                            left: parent.left
                            leftMargin: leftPadding
                            verticalCenter: parent.verticalCenter
                        }
                        text: title
                    }
                    onClicked: {
                        var _props =  {
                            booruSite: booruSite,
                            pxvOnly: pxvOnly,
                            searchTags: "parent:" + searchID,
                            fromBooruId: 0
                        };
                        pageStack.push("BooruPage.qml", _props);
                    }
                }
            }

            ListView {
                anchors.top: familyList.bottom
                anchors.topMargin: 10
                width: parent.width
                height: childrenRect.height

                model: tagModel
                delegate: ListItem {
                    width: parent.width
                    height: Theme.itemSizeSmall
                    Label {
                        width: parent.width - leftPadding*2
                        anchors.centerIn: parent
                        color: Theme.secondaryHighlightColor
                        text: tag
                    }
                    onClicked: {
                        if (debugOn) console.log('tag clicked', tag);
                        if (tag === fromTags) {
                            if (debugOn) console.log('pop back to same tag')
                            pageStack.pop()
                        } else {
                            pageStack.push("BooruPage.qml", {
                                               booruSite: booruSite,
                                               pxvOnly: pxvOnly,
                                               searchTags: tag,
                                               fromBooruId: workID
                                           });
                        }
                    }
                }
            }
        }

    }


    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (debugOn) console.log("detail page actived: " + workID)
        }

        /* TODO Cover
         *
         */
    }

    Component.onCompleted: {
        if (debugOn) console.log("details onCompleted")

        var tags = work.tags.split(' ')
        tagModel.clear()
        for (var i in tags) {
            tagModel.append( { tag: tags[i] } )
        }

        if (work['parentID']) {
            familyModel.append({ title: "Parent " + work['parentID'], searchID: work['parentID'] });
        }
        if (work['hasChildren']) {
            familyModel.append({ title: "View children", searchID: work['workID'] });
        }

        getFavedUsers();
    }
}

