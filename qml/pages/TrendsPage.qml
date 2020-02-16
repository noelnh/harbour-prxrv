import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/pixiv.js" as Pixiv

Page {
    id: trendsPage

    property var searchParams: { 'mode': 'tag', 'period': 'all', 'sort': 'popular', 'order': 'desc' }

    function doSearch() {
        searchParams.q = searchTextField.text
        if (searchParams.q) {
            if (searchParams.mode === 'member_id') {
                var member_id = searchParams.q
                if (!isNaN(member_id)) {
                    currentModel.push("userWorkModel")
                    var _props = {"authorName": "", "authorID": member_id}
                    pageStack.push("UserWorkPage.qml", _props)
                }
            } else if (searchParams.mode === 'illust_id') {
                var illust_id = searchParams.q
                if (!isNaN(illust_id)) {
                    var _props = {"workID": illust_id, "authorID": "", "currentIndex": -1}
                    pageStack.push("DetailPage.qml", _props)
                }
            } else {
                currentModel.push("worksSearchModel")
                pageStack.push("WorksSearchPage.qml", { searchParams: searchParams, fromTag: '' })
                coverIndex[0] = 0   // for tag search from DetailPage
            }
        } else {
            searchTextField.focus = true
        }
    }

    function setTags (resp_j) {
        for (var i in resp_j['trend_tags']) {
            tagModel.append(resp_j['trend_tags'][i])
        }
        pageStack.pushAttached(tagIllustPage)
    }

    ListModel { id: tagModel }

    Component {
        id: tagIllustPage

        Page {
            SilicaListView {
                anchors.fill: parent

                header: PageHeader {
                    width: parent.width
                    title: qsTr("Trending Tags")
                }

                model: tagModel

                delegate: ListItem {
                    width: parent.width
                    contentHeight: tagImage.height || Theme.itemSizeLarge
                    Image {
                        id: tagImage
                        anchors.right: parent.right
                        source: illust['image_urls']['large']
                    }
                    Item {
                        id: authorBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingSmall
                        height: Theme.itemSizeSmall
                        Image {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            height: parent.height
                            width: height
                            source: illust['user']['profile_image_urls']['medium']
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: parent.height + Theme.paddingSmall * 2
                            anchors.top: parent.top
                            height: parent.height / 2
                            text: illust['title']
                            color: Theme.highlightColor
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: parent.height + Theme.paddingSmall * 2
                            anchors.bottom: parent.bottom
                            height: parent.height / 2
                            text: illust['user']['name']
                            color: Theme.secondaryColor
                        }
                    }
                    Label {
                        anchors.left: parent.left
                        anchors.top: authorBar.bottom
                        anchors.leftMargin: Theme.paddingSmall
                        anchors.topMargin: Theme.paddingSmall
                        text: '#' + tag
                    }

                    menu: ContextMenu {
                        MenuItem {
                          text: qsTr("Search %1").arg(tag)
                          onClicked: {
                              searchTextField.text = tag
                              modeCombo.currentIndex = 0
                              doSearch()
                          }
                        }
                    }

                    onClicked: {
                        var _props = {"workID": illust['id'], "authorID": illust['user']['id'], "currentIndex": -1}
                        pageStack.push("DetailPage.qml", _props)
                    }
                }
            }
        }
    }

    SilicaFlickable {
        id: trendsFlickable
        anchors.fill: parent

        Column {
            id: searchForm
            anchors.top: parent.top
            width: parent.width

            PageHeader {
                id: pageHeader
                width: parent.width
                title: qsTr("Search")
            }

            SearchField {
                id: searchTextField
                width: parent.width
                placeholderText: qsTr("Search")

                text: searchParams.q || ""

                EnterKey.enabled: searchTextField.text
                EnterKey.text: qsTr("Search")
                EnterKey.onClicked: doSearch()
            }

            ComboBox {
                id: modeCombo
                width: parent.width

                property var values: ['tag', 'caption', 'text', 'illust_id', 'member_id']

                currentIndex: values.indexOf(searchParams.mode)

                label: qsTr("Search in")
                menu: ContextMenu {
                    MenuItem { text: qsTr("tag") }
                    MenuItem { text: qsTr("caption") }
                    MenuItem { text: qsTr("text") }
                    MenuItem { text: qsTr("illust ID") }
                    MenuItem { text: qsTr("member ID") }
                }
                onValueChanged: {
                    searchParams.mode = values[currentIndex] || values[0]
                }
            }

            ComboBox {
                id: periodCombo
                width: parent.width

                property var values: ['all', 'month', 'week', 'day']

                currentIndex: values.indexOf(searchParams.period)

                label: qsTr("Period")
                menu: ContextMenu {
                    MenuItem { text: qsTr("all time") }
                    MenuItem { text: qsTr("last month") }
                    MenuItem { text: qsTr("last week") }
                    MenuItem { text: qsTr("last day") }
                }
                onValueChanged: {
                    searchParams.period = values[currentIndex] || values[0]
                }
            }

            ComboBox {
                id: sortCombo
                width: parent.width

                property var values: ['popular', 'date']

                currentIndex: values.indexOf(searchParams.sort)

                label: qsTr("Sort by")
                menu: ContextMenu {
                    MenuItem { text: qsTr("popular") }
                    MenuItem { text: qsTr("date") }
                }
                onValueChanged: {
                    searchParams.sort = values[currentIndex] || values[0]
                    if (value == 'popular') {
                        orderCombo.currentIndex = 0
                    }
                }
            }

            ComboBox {
                id: orderCombo
                width: parent.width

                property var values: ['desc', 'asc']

                currentIndex: values.indexOf(searchParams.order)

                label: qsTr("Order")
                menu: ContextMenu {
                    MenuItem { text: qsTr("desc") }
                    MenuItem {
                        text: qsTr("asc")
                        visible: sortCombo.currentIndex
                    }
                }
                onValueChanged: {
                    searchParams.order = values[currentIndex] || values[0]
                }
            }

            Item {
                id: largeWhiteSpaceInColumn
                width: parent.width
                height: Theme.paddingLarge
            }

            Button {
                id: searchButton
                width: parent.width - Theme.paddingLarge*2
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Search")
                onClicked: doSearch()
            }

            SectionHeader {
                id: trendingTagsHeader
                height: Theme.itemSizeSmall
                text: qsTr("Trending tags")
            }
        }

        ListView {
            anchors.top: searchForm.bottom
            anchors.bottom: parent.bottom
            width: parent.width
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
                    searchTextField.text = tag
                    modeCombo.currentIndex = 0
                    doSearch()
                }

            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            // set cover to previous DetailPage's index
            coverIndex[0] = coverIndex[coverIndex.length - 1]
        }
    }

    Component.onCompleted: {
        Pixiv.getTrendingTags(token, setTags)
    }
}
