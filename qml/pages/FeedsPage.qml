import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: feedsPage

    property string userID: ""
    property string userName: ""

    property bool isNewModel: true

    property bool notEmptyFeed: true

    property var feedArray: []

    ListModel { id: feedsModel }

    function addActivities(resp_j) {
        requestLock = false;
        if (!resp_j) return;

        if (resp_j['count'] == 0) notEmptyFeed = false;

        var activities = resp_j['response'];
        if (debugOn) console.log('adding activities to feedsModel');
        for (var i in activities) {

            var activityID = parseInt(activities[i]['id']);
            if ( activityID < minActivityID) {
                minActivityID = activityID; 
            }

            var activity_type = activities[i]['type'];
            if (activity_type != 'add_illust' && activity_type != 'add_bookmark') continue;

            var work_id = activities[i]['ref_work']['id'];
            if ( feedArray.indexOf(work_id) > -1 ) {
                if (debugOn) console.log('Already in pool: ' + work_id);
                continue;
            }

            var user_name = activities[i]['user']['name'];

            feedArray.push(work_id);

            feedsModel.append( {
                headerText: user_name + ' ' + Prxrv.getActionName(activity_type),
                title: activities[i]['ref_work']['title'],
                userName: user_name,
                userIcon: activities[i]['user']['profile_image_urls']['px_50x50'],
                activityType: activity_type,
                activityTime: activities[i]['post_time'],
                workID: work_id,
                square128: activities[i]['ref_work']['image_urls']['px_128x128'],
                master240: activities[i]['ref_work']['image_urls']['max_240x240'],
                master480: activities[i]['ref_work']['image_urls']['px_480mw'],
                //large: activities[i]['ref_work']['image_urls']['large'],  // large is not available
                authorIcon: activities[i]['ref_work']['user']['profile_image_urls']['px_50x50'],
                authorID: activities[i]['ref_work']['user']['id'],
                authorName: activities[i]['ref_work']['user']['name'],
            } );
        }
    }


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

                Label {
                    id: titleLabel
                    width: parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignLeft
                    elide: TruncationMode.Elide
                    text: title
                }

                // Author Bar
                Item {
                    id: authorBar
                    height: childrenRect.height
                    anchors.top: titleLabel.bottom
                    anchors.topMargin: Theme.paddingMedium
                    anchors.left: parent.left
                    anchors.right: parent.right
                    Image {
                        id: authorIconImage
                        width: 80
                        height: width
                        anchors.top: parent.top
                        anchors.left: parent.left
                        source: authorIcon
                    }
                    Column {
                        height: 80
                        anchors.top: parent.top
                        anchors.left: authorIconImage.right
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.paddingMedium
                        Label {
                            width: parent.width
                            color: Theme.secondaryColor
                            horizontalAlignment: Text.AlignLeft
                            elide: TruncationMode.Elide
                            text: qsTr("by")
                        }
                        Label {
                            id: authorNameLabel
                            width: parent.width
                            color: Theme.primaryColor
                            horizontalAlignment: Text.AlignLeft
                            text: authorName
                        }
                    }
                }

                // User Bar
                Item {
                    id: userActionLabels
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingLarge * 1.5

                    Label {
                        id: actionLabel
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        anchors.bottom: parent.bottom
                        horizontalAlignment: Text.AlignRight
                        color: Prxrv.getActionType(activityType).color
                        font.family: 'FontAwesome'
                        text: Prxrv.getActionType(activityType).type
                    }

                    Label {
                        id: dateLabel
                        width: parent.width
                        anchors.bottom: parent.bottom
                        anchors.right: actionLabel.left
                        anchors.rightMargin: Theme.paddingMedium
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignRight
                        text: Prxrv.getDuration(activityTime) + qsTr(" ago")
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

        model: feedsModel
        delegate: activityDelegate

        header: PageHeader {
            title: userName + qsTr("'s Activity")
        }

        FontLoader {
            source: '../fonts/fontawesome-webfont.ttf'
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Go Home")
                onClicked: {
                    while (currentModel.length) currentModel.pop()
                    while (worksModelStack.length) worksModelStack.pop()
                    pageStack.pop(firstPage)
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (userID && loginCheck()) {
                        feedsModel.clear()
                        feedArray = []
                        Pixiv.getFeeds(token, userID, showR18, addActivities)
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || ( !feedsModel.count && notEmptyFeed )
        }

        onAtYEndChanged: {
            if (listView.atYEnd) {
                if ( !requestLock && feedsModel.count > 0 && loginCheck() ) {
                    requestLock = true
                    Pixiv.getFeeds(token, userID, showR18, addActivities, minActivityID - 1)
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (_navigation == PageNavigation.Back) {
                if (debugOn) console.log("navigated back")
                if (currentModel[currentModel.length-1] == "feedsModel" && worksModelStack.length) {
                    worksModelStack.pop()
                    var _popModel = currentModel.pop()
                    if (debugOn) console.log("pop model: " + _popModel)
                }
            }
        }
    }

    Component.onCompleted: {
        if (isNewModel) {
            worksModelStack.push(feedsModel)
            isNewModel = false
        }
        if (feedsModel.count == 0) {
            if(userID && loginCheck()) {
                feedArray = []
                Pixiv.getFeeds(token, userID, showR18, addActivities)
            } else {
                // Try again
            }
        }
    }
}


