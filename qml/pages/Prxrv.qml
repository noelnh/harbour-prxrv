import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv

Page {
    id: mainPage

    property string version: ""
    property string buildNum: ""

    SilicaListView {
        id: homeListView

        anchors.fill: parent

        header: PageHeader {
            id: mainHeader
            title: "Prxrv"
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                // TODO
                text: "About"
                onClicked: {
                    pageStack.push("AboutPage.qml")
                }
                visible: false
            }
            MenuItem {
                text: "Settings"
                onClicked: {
                    pageStack.push("SettingsPage.qml")
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: token == "" && Boolean(user.name)
        }

        model: ListModel {
//            ListElement {
//                label: "Stacc"
//                model: "activityModel"
//                page: "StaccPage.qml"
//            }
            ListElement {
                label: "New Works"
                model: "latestWorkModel"
                page: "LatestWorkPage.qml"
            }
            ListElement {
                label: "Recommendation"
                model: "recommendationModel"
                page: "RecommendationPage.qml"
            }
            ListElement {
                label: "Rankings"
                model: "rankingWorkModel"
                page: "RankingPage.qml"
            }
            ListElement {
                label: "Bookmarks"
                model: "favoriteWorkModel"
                page: "FavoriteWorkPage.qml"
            }
            ListElement {
                label: "Search"
                model: ""
                page: "TrendsPage.qml"
            }
            ListElement {
                label: "Profile"
                model: ""
                page: "ProfilePage.qml"
            }
            ListElement {
                label: "Downloads"
                model: "downloadsModel"
                page: "DownloadsPage.qml"
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width
            contentHeight: Theme.itemSizeMedium
            Label {
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.centerIn: parent
                text: label
            }
            onClicked: {
                firstPage = pageStack.currentPage
                if (page == 'ProfilePage.qml') {
                    if (debugOn) console.log( user['id'], user['name'] )
                    var _props =  {"userID": user['id'], "userName": user['name']}
                    pageStack.push(page, _props)
                } else if (token) {
                    if (model) currentModel = [model,]
                    coverIndex = [0,]
                    if (label === 'Stacc' && staccListMode) {
                        pageStack.push('StaccListPage.qml')
                    } else {
                        pageStack.push(page)
                    }
                }
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            // TODO side menu
            if (debugOn) console.log('page _navigation:', _navigation)
            if (debugOn) console.log('username', user.name)
            if (!user.name) {
                pageStack.push("SettingsPage.qml")
            }
        }
    }

    Component.onCompleted: {
        loginCheck()
        requestMgr.downloadProgress.connect(updateProgress)
        requestMgr.allImagesSaved.connect(notifyDownloadsFinished)
        requestMgr.errorMessage.connect(showErrorMessage)
    }

}

