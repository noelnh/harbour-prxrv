import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: feedsPage


    Component {
        id: activityDelegate

        ListItem {
            id: listItem
            width: parent.width
            height: 240
            contentHeight: height

            Separator {
                width: parent.width
                color: Theme.secondaryColor
            }

            Image {
                id: mainImage
                anchors.top: parent.top
                anchors.left: parent.left
                height: listItem.height
                width: height
                fillMode: Image.PreserveAspectCrop
                source: master240
            }

            Item {
                height: listItem.height
                anchors.top: parent.top
                anchors.left: mainImage.right
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium

                // Title
                Label {
                    id: titleLabel
                    width: parent.width
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingSmall
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignLeft
                    elide: TruncationMode.Elide
                    text: title
                }
                Label {
                    id: authorNameLabel
                    anchors.top: titleLabel.bottom
                    anchors.topMargin: Theme.paddingSmall
                    anchors.left: parent.left
                    width: parent.width
                    color: Theme.primaryColor
                    horizontalAlignment: Text.AlignLeft
                    elide: TruncationMode.Elide
                    text: qsTr("by ") + authorName
                }

                /*
                 // Author Bar
                 Item {
                     id: authorBar
                     height: childrenRect.height
                     anchors.top: titleLabel.bottom
                     anchors.topMargin: Theme.paddingMedium
                     anchors.left: parent.left
                     Image {
                         id: authorIconImage
                         width: 80
                         height: width
                         anchors.top: parent.top
                         anchors.left: parent.left
                         source: authorIcon
                     }
                     Item {
                         height: 80
                         anchors.top: parent.top
                         anchors.left: authorIconImage.right
                         anchors.right: parent.right
                         anchors.leftMargin: Theme.paddingMedium
                         Label {
                             id: authorNameLabel
                             width: parent.width
                             color: Theme.primaryColor
                             horizontalAlignment: Text.AlignLeft
                             text: authorName
                         }
                         Label {
                             width: parent.width
                             color: Theme.secondaryColor
                             horizontalAlignment: Text.AlignLeft
                             text: Prxrv.getDuration(activityTime) + qsTr(" ago")
                         }
                     }
                 }
                 */

                // User Bar
                Item {
                    id: userBar
                    height: 80
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottomMargin: Theme.paddingLarge * 1.5

                    Image {
                        id: userIconImage
                        width: 80
                        height: width
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        source: userIcon
                    }

                    Item {
                        height: 80
                        anchors.bottom: parent.bottom
                        anchors.left: userIconImage.right
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.paddingMedium

                        Label {
                            id: actionLabel
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.bottom: atimeLabel.top
                            color: Prxrv.getActionType(activityType).color
                            font.family: 'FontAwesome'
                            text: Prxrv.getActionType(activityType).type
                        }
                        Label {
                            id: atimeLabel
                            width: parent.width
                            anchors.bottom: parent.bottom
                            color: Theme.secondaryColor
                            horizontalAlignment: Text.AlignLeft
                            text: Prxrv.getDuration(activityTime) + qsTr(" ago")
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

    SilicaListView {
        id: listView

        anchors.fill: parent

        model: activityModel
        delegate: activityDelegate

        header: PageHeader {
            title: qsTr("All Activity")
        }

        FontLoader {
            source: '../fonts/fontawesome-webfont.ttf'
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: toggleViewAction
                text: qsTr("Grid View")
                onClicked: {
                    pageStack.replace("StaccPage.qml")
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        activityModel.clear()
                        illustArray = []
                        console.log("refresh stacc")
                        Pixiv.getStacc(token, showR18, Prxrv.addActivities)
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !activityModel.count
        }

        onAtYEndChanged: {
            if (debugOn) console.log('at y end changed')
            if (listView.atYEnd && minActivityID < 2000000000) {
                console.log('listView at end')
                if ( !requestLock && activityModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    Pixiv.getStacc(token, showR18, Prxrv.addActivities, minActivityID - 1)
                }
            }
        }

    }


    Component.onCompleted: {
        console.log("onCompleted")
        if (activityModel.count == 0) {
            illustArray = []
            if(loginCheck()) {
                Pixiv.getStacc(token, showR18, Prxrv.addActivities)
            } else {
                // Try again
            }
        }
    }
}


