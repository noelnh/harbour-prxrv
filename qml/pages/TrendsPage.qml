import QtQuick 2.2
import Sailfish.Silica 1.0

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
            }
        } else {
            searchTextField.focus = true
        }
    }

    SilicaFlickable {
        id: trendsFlickable
        anchors.fill: parent

        SearchField {
            id: searchTextField
            width: parent.width
            placeholderText: qsTr("Search")

            text: searchParams.q || ""

            EnterKey.enabled: searchTextField.text
            EnterKey.text: qsTr("Search")
            EnterKey.onClicked: doSearch()
        }

        Column {
            width: parent.width
            anchors.top: searchTextField.bottom

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
        }

    }

}
