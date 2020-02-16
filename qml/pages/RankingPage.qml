import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv
import "../js/prxrv.js" as Prxrv

Page {
    id: rankingPage

    property int currentPage: 1
    property int currentIndex: -1
    property int totalWork: 500
    property int hiddenWork: 0

    property string rankingType: "all"
    property string rankingMode: "daily"

    property bool refreshRanking: false
    property var typeArray: [0, 0]

    function getTextTr (text) {
        return {
            // type
            all: qsTr("all"),
            illust: qsTr("illust"),
            manga: qsTr("manga"),
            ugoira: qsTr("ugoira"),
            novel: qsTr("novel"),
            // mode
            daily: qsTr("daily"),
            weekly: qsTr("weekly"),
            monthly: qsTr("monthly"),
            rookie: qsTr("rookie"),
            original: qsTr("original"),
            male: qsTr("male"),
            female: qsTr("female"),
            daily_r18: qsTr("daily_r18"),
            weekly_r18: qsTr("weekly_r18"),
            male_r18: qsTr("male_r18"),
            female_r18: qsTr("female_r18"),
            r18g: qsTr("r18g"),
        }[text] || text
    }

    function addRankingWork(resp_j) {
        requestLock = false;
        if (!resp_j) return;

        totalWork = resp_j['pagination']['total']

        var works = resp_j['response'][0]['works'];

        if (debugOn) console.log('adding works to rankingWorkModel');
        for (var i in works) {
            if (!showR18 && works[i]['work']['age_limit'].indexOf('r18') >= 0) {
                hiddenWork += 1
                continue
            }
            rankingWorkModel.append({
                workID: works[i]['work']['id'],
                title: works[i]['work']['title'],
                headerText: works[i]['rank'] + '. ' + works[i]['work']['title'],
                square128: works[i]['work']['image_urls']['px_128x128'],
                master480: works[i]['work']['image_urls']['px_480mw'],
                large: works[i]['work']['image_urls']['large'],
                authorIcon: works[i]['work']['user']['profile_image_urls']['px_50x50'],
                authorID: works[i]['work']['user']['id'],
                authorName: works[i]['work']['user']['name'],
                authorAccount: works[i]['work']['user']['account'],
                rankUp: works[i]['previous_rank'] - works[i]['rank'],
                isManga: works[i]['work']['page_count'] > 1
            });
        }
    }


    Component {
        id: modeDialog

        Dialog {
            id: theDialog

            function checkType() {
                var _illustArray = [0, 1, 2, 3, 7, 8, 11]
                var _ugoiraArray = [0, 1, 7, 8]
                var _novelArray = [0, 1, 3, 5, 6, 7, 8, 9, 10, 11]
                var _warning = qsTr("%1 | %2: not supported").arg(contentCombo.value).arg(modeCombo.value)
                theDialog.canAccept = true
                typeWarning.text = ""
                switch (contentCombo.value) {
                    case "illust":
                    case "manga":
                        if (_illustArray.indexOf(modeCombo.currentIndex)<0) {
                            typeWarning.text = _warning
                            theDialog.canAccept = false
                        }
                        break
                    case "ugoira":
                        if (_ugoiraArray.indexOf(modeCombo.currentIndex)<0) {
                            typeWarning.text = _warning
                            theDialog.canAccept = false
                        }
                        break
                    case "novel":
                        if (_novelArray.indexOf(modeCombo.currentIndex)<0) {
                            typeWarning.text = _warning
                            theDialog.canAccept = false
                        }
                        break
                }
            }

            Column {
                width: parent.width

                DialogHeader {
                    title: qsTr("Choose")
                }

                ComboBox {
                    id: contentCombo
                    width: parent.width
                    label: qsTr("Content")

                    currentIndex: typeArray[0]

                    menu: ContextMenu {
                        MenuItem { text: getTextTr("all") }        // all
                        MenuItem { text: getTextTr("illust") }     // daily, weekly, monthly, rookie, r18 x5
                        MenuItem { text: getTextTr("manga") }      // =illust
                        MenuItem { text: getTextTr("ugoira") }     // daily, weekly, r18 x2
                        MenuItem { text: getTextTr("novel") }      // daily, weekly, rookie, male, female, r18 x5
                    }

                    onValueChanged: {
                        checkType()
                    }
                }

                ComboBox {
                    id: modeCombo
                    width: parent.width
                    label: qsTr("Mode")

                    currentIndex: typeArray[1]

                    menu: ContextMenu {
                        MenuItem { text: getTextTr("daily") }
                        MenuItem { text: getTextTr("weekly") }
                        MenuItem { text: getTextTr("monthly") }
                        MenuItem { text: getTextTr("rookie") }
                        MenuItem { text: getTextTr("original") }
                        MenuItem { text: getTextTr("male") }
                        MenuItem { text: getTextTr("female") }
                        MenuItem { text: getTextTr("daily_r18") }
                        MenuItem { text: getTextTr("weekly_r18") }
                        MenuItem { text: getTextTr("male_r18") }
                        MenuItem { text: getTextTr("female_r18") }
                        MenuItem { text: getTextTr("r18g") }
                    }

                    onValueChanged: {
                        checkType()
                    }
                }

                Label {
                    id: typeWarning
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: ""
                }
            }

            onAccepted: {
                if ( rankingMode != modeCombo.value || rankingType != contentCombo.value ) {
                    refreshRanking = true
                }
                rankingMode = modeCombo.value
                rankingType = contentCombo.value
                typeArray = [contentCombo.currentIndex, modeCombo.currentIndex]
                if (debugOn) console.log('content: ' + contentCombo.value)
                if (debugOn) console.log('mode: ' + rankingMode)
                pageStack.popAttached()
            }
        }
    }

    Component {
        id: rankingWorkDelegate

        BackgroundItem {
            width: gridView.cellWidth
            height: width

            Image {
                anchors.centerIn: parent
                width: gridView.cellWidth
                height: width
                source: square128

                Image {
                    visible: isManga
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width / 6
                    height: width
                    source: "../images/manga-icon.svg"
                }
                /*
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: favoriteID ? "../images/btn-done.svg" : "../images/btn-like.svg"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, favoriteID)
                        }
                    }
                }
                */
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

        model: rankingWorkModel
        delegate: rankingWorkDelegate

        header: PageHeader {
            title: qsTr("Ranking: ") + getTextTr(rankingMode) + ' | ' + getTextTr(rankingType)
        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    if (loginCheck()) {
                        rankingWorkModel.clear()
                        currentPage = 1
                        hiddenWork = 0
                        Pixiv.getRankingWork(token, rankingType, rankingMode, currentPage, addRankingWork)
                    }
                }
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: requestLock || !rankingWorkModel.count
        }

        onAtYEndChanged: {
            if (gridView.atYEnd) {
                if ( !requestLock && rankingWorkModel.count > 0
                        && rankingWorkModel.count < totalWork - hiddenWork && loginCheck() ) {
                    requestLock = true
                    currentPage += 1
                    Pixiv.getRankingWork(token, rankingType, rankingMode, currentPage, addRankingWork)
                }
            }
        }

    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (debugOn) console.log("ranking page actived")
            pageStack.pushAttached(modeDialog)
            if (refreshRanking && loginCheck()) {
                if (debugOn) console.log("refresh ranking page")
                if (debugOn) console.log("type: " + rankingType)
                if (debugOn) console.log("mode: " + rankingMode)
                currentPage = 1
                hiddenWork = 0
                rankingWorkModel.clear()
                Pixiv.getRankingWork(token, rankingType, rankingMode, currentPage, addRankingWork)
                refreshRanking = false
            }
        }
    }

    Component.onCompleted: {
        if (rankingWorkModel.count == 0) {
            if(loginCheck()) {
                currentPage = 1
                Pixiv.getRankingWork(token, rankingType, rankingMode, currentPage, addRankingWork)
            } else {
                // Try again
            }
        }
    }
}


