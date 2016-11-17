import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv
import "../js/storage.js" as Storage

Page {
    id: staccPage

    Component {
        id: activityDelegate

        BackgroundItem {
            width: gridView.cellWidth
            height: width

            Image {
                anchors.centerIn: parent
                width: gridView.cellWidth
                height: width
                source: square128

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

        model: activityModel
        delegate: activityDelegate

        header: PageHeader {
            title: qsTr("All Activity")
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                id: toggleViewAction
                text: qsTr("List View")
                onClicked: {
                    pageStack.replace("StaccListPage.qml")
                    staccListMode = true
                    Storage.writeSetting('staccListMode', true)
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        activityModel.clear()
                        illustArray = []
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
            if (gridView.atYEnd && minActivityID > 0) {
                if ( !requestLock && activityModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    Pixiv.getStacc(token, showR18, Prxrv.addActivities, minActivityID - 1)
                }
            }
        }

    }

    Component.onCompleted: {
        if (activityModel.count == 0) {
            illustArray = []
            if(loginCheck()) {
                Pixiv.getStacc(token, showR18, function(activities) {
                    Prxrv.addActivities(activities, []);
                });
            } else {
                // Try again
            }
        }
    }
}


