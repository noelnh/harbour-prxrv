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

    property string rankingType: "illust"
    property string rankingMode: "day"

    property bool refreshRanking: false
    property var typeArray: [0, 0]
    property int currentRank: 0

    function getTextTr (text) {
        return {
            // type
            illust: qsTr("illust"),
            manga: qsTr("manga"),
            // mode
            day: qsTr("daily"),
            week: qsTr("weekly"),
            month: qsTr("monthly"),
            day_male: qsTr("day_male"),
            day_female: qsTr("day_female"),
            week_original: qsTr("week_original"),
            week_rookie: qsTr("week_rookie"),
            day_r18: qsTr("day_r18"),
            day_male_r18: qsTr("male_r18"),
            day_female_r18: qsTr("female_r18"),
            week_r18: qsTr("week_r18"),
            week_r18g: qsTr("week_r18g"),
        }[text] || text
    }

    function addRankingWork(resp_j) {
        requestLock = false;
        if (!resp_j) return;

        var works = resp_j['illusts'];

        if (debugOn) console.log('adding works to rankingWorkModel');
        for (var i in works) {
            currentRank += 1
            if ((!showR18 && works[i]['x_restrict'] > 0) || works[i]['sanity_level'] > sanityLevel) {
                hiddenWork += 1
                continue
            }
            var imgUrls = Prxrv.getImgUrls(works[i])
            rankingWorkModel.append({
                workID: works[i]['id'],
                title: works[i]['title'],
                headerText: currentRank + '. ' + works[i]['title'],
                square128: imgUrls.square,
                master480: imgUrls.master,
                large: imgUrls.large,
                authorIcon: works[i]['user']['profile_image_urls']['medium'],
                authorID: works[i]['user']['id'],
                authorName: works[i]['user']['name'],
                authorAccount: works[i]['user']['account'],
                isBookmarked: works[i]['is_bookmarked'],
                isManga: works[i]['page_count'] > 1
            });
        }
    }


    Component {
        id: modeDialog

        Dialog {
            id: theDialog

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
                    property var values: ['illust', 'manga']

                    menu: ContextMenu {
                        MenuItem { text: getTextTr("illust") }
                        MenuItem { text: getTextTr("manga") }
                    }

                    onValueChanged: {
                        rankingType = values[currentIndex] || values[0]
                    }
                }

                ComboBox {
                    id: modeCombo
                    width: parent.width
                    label: qsTr("Mode")
                    visible: rankingType !== 'manga'

                    currentIndex: typeArray[1]

                    property var values: [
                        "day",
                        "week",
                        "month",
                        "day_male",
                        "day_female",
                        "week_original",
                        "week_rookie",
                        "day_r18",
                        "day_male_r18",
                        "day_female_r18",
                        "week_r18",
                        "week_r18g",
                    ]

                    menu: ContextMenu {
                        MenuItem { text: getTextTr("day") }
                        MenuItem { text: getTextTr("week") }
                        MenuItem { text: getTextTr("month") }
                        MenuItem { text: getTextTr("day_male") }
                        MenuItem { text: getTextTr("day_female") }
                        MenuItem { text: getTextTr("week_rookie") }
                        MenuItem { text: getTextTr("week_original") }
                        MenuItem {
                            visible: showR18
                            text: getTextTr("day_r18")
                        }
                        MenuItem {
                            visible: showR18
                            text: getTextTr("day_male_r18")
                        }
                        MenuItem {
                            visible: showR18
                            text: getTextTr("day_female_r18")
                        }
                        MenuItem {
                            visible: showR18
                            text: getTextTr("week_r18")
                        }
                        MenuItem {
                            visible: showR18
                            text: getTextTr("week_r18g")
                        }
                    }

                    onValueChanged: {
                        rankingMode = values[currentIndex] || values[0]
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
                if ( typeArray[0] !== contentCombo.currentIndex || typeArray[1] !== modeCombo.currentIndex ) {
                    refreshRanking = true
                }
                typeArray = [contentCombo.currentIndex, modeCombo.currentIndex]
                if (debugOn) console.log('content: ' + rankingType)
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
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: isBookmarked ? "../images/btn-done.svg" : "../images/btn-like.svg"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            currentIndex = index
                            Prxrv.toggleBookmarkIcon(workID, !isBookmarked)
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

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width / 3
        cellHeight: cellWidth

        model: rankingWorkModel
        delegate: rankingWorkDelegate

        header: PageHeader {
            title: qsTr("Ranking: ") + (rankingType !== 'manga' ? getTextTr(rankingMode) : getTextTr('day')) + ' | ' + getTextTr(rankingType)
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
                currentRank = 0
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


