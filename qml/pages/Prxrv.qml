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
                text: qsTr("About")
                onClicked: {
                    pageStack.push("AboutPage.qml")
                }
                visible: false
            }
            MenuItem {
                text: qsTr("Accounts")
                onClicked: {
                    pageStack.push("AccountsPage.qml")
                }
            }
            MenuItem {
                text: qsTr("Settings")
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
//                label: qsTr("Stacc")
//                model: "activityModel"
//                page: "StaccPage.qml"
//            }
            ListElement {
                label: qsTr("Newest Works")
                model: "followingWorksModel"
                page: "FollowingWorksPage.qml"
            }
            ListElement {
                label: qsTr("Recommendation")
                model: "recommendationModel"
                page: "RecommendationPage.qml"
            }
            ListElement {
                label: qsTr("Rankings")
                model: "rankingWorkModel"
                page: "RankingPage.qml"
            }
            ListElement {
                label: qsTr("Bookmarks")
                model: "favoriteWorkModel"
                page: "FavoriteWorkPage.qml"
            }
            ListElement {
                label: qsTr("Search")
                model: ""
                page: "TrendsPage.qml"
            }
            ListElement {
                label: qsTr("Profile")
                model: ""
                page: "ProfilePage.qml"
            }
            ListElement {
                label: qsTr("Downloads")
                model: "downloadsModel"
                page: "DownloadsPage.qml"
            }
            ListElement {
                label: qsTr("Moebooru")
                model: "booruModel"
                page: "/usr/share/harbour-mieru/qml/pages/MainPage.qml"
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width
            visible: model != "booruModel" || booruEnabled
            contentHeight: Theme.itemSizeMedium
            Label {
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.centerIn: parent
                text: label
            }
            onClicked: {
                firstPage = pageStack.currentPage
                if (page == 'ProfilePage.qml') {
                    var _props =  {"userID": user['id'], "userName": user['name']}
                    pageStack.push(page, _props)
                } else if (page == 'FavoriteWorkPage.qml') {
                    if (model) currentModel = [model,]
                    var _props =  {"userID": user['id'], "userName": user['name'], "mine": true}
                    pageStack.push(page, _props)
                } else if (model === 'booruModel') {
                    pageStack.push(page)
                    toReloadAccounts = true
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
            console.log('Debug mode:', debugOn)
            // TODO side menu
            if (!user.name) {
                pageStack.push("AccountsPage.qml")
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

