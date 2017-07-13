import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: optionsDialog

    property int _currentPage: 1
    property string _tags: ''
    property string _siteName: '?'

    ListModel { id: tagsModel }

    SilicaFlickable {
        id: optionsFlicableView

        contentHeight: optionsColumn.height
        anchors.fill: parent

        Column {
            id: optionsColumn
            width: parent.width

            DialogHeader {
            }

            SectionHeader {
                text: qsTr("Go to page")
            }

            TextField {
                id: pageNumField
                width: parent.width
                label: qsTr("page number")
                placeholderText: _currentPage
                validator: RegExpValidator { regExp: /^\d*$/ }
                inputMethodHints: Qt.ImhDigitsOnly
            }

            SectionHeader {
                text: qsTr("Filters")
            }

            TextSwitch {
                id: limitSwitch
                text: qsTr("Show R-18 works")
                checked: showR18
                onCheckedChanged: {
                }
            }

            SectionHeader {
                text: qsTr("Behavior")
            }

            TextSwitch {
                id: pxvSwitch
                text: qsTr("Open pixiv details")
                checked: openPxvDetails
                onCheckedChanged: {
                }
            }

            TextSwitch {
                id: sampleSwitch
                text: qsTr("Load large preview")
                checked: loadSample
                onCheckedChanged: {
                }
            }

            SectionHeader {
                text: qsTr("Tags")
            }

            TextField {
                id: tagsField
                width: parent.width
                label: qsTr("Search Tags")
                text: _tags
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            Repeater {
                id: tagRepeater
                model: tagsModel
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: parent.width
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: removeTag(index, tag)
                        }
                    }

                    Label {
                        width: parent.width
                        anchors {
                            left: parent.left
                            leftMargin: leftPadding
                            verticalCenter: parent.verticalCenter
                        }
                        text: tag
                    }
                    onClicked: {
                        if (debugOn) console.log('tag clicked', index, tag);
                        if (tagsModel.count > 1) {
                            pageStack.push("ListPage.qml", {
                                               siteName: _siteName,
                                               searchTags: tag,
                                           });
                        } else {
                            pageStack.navigateBack();
                        }
                    }
                }
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            _currentPage = pageStack.previousPage().currentPage || _currentPage;
        }
    }

    Component.onCompleted: {
        tagsModel.clear()
        if (_tags) {
            if (_tags[_tags.length-1] !== ' ') {
                tagsField.text += ' '
            }

            var tags = _tags.split(' ')
            tags.forEach(function(tag) {
                if (tag !== '') tagsModel.append({tag: tag})
            })
        }
    }

    onAccepted: {
        var toReload = false;

        var pageNum = pageNumField.text;
        if (pageNum && _currentPage != pageNum) {
            if (pageNum) _currentPage = parseInt(pageNum);
            toReload = true;
        }

        if (limitSwitch.checked != showR18) {
            showR18 = limitSwitch.checked;
            toReload = true;
        }

        if (pxvSwitch.checked != openPxvDetails) {
            openPxvDetails = pxvSwitch.checked;
        }

        if (sampleSwitch.checked != loadSample) {
            loadSample = sampleSwitch.checked;
        }

        var fieldText = tagsField.text.replace(/ +$/, '')
        if (fieldText !== _tags.replace(/ +$/, '')) {
            _tags = fieldText;
            toReload = true;
        }

        if (toReload) {
            pageStack.previousPage().reloadPostList(_currentPage, _tags);
        }

        pageStack.popAttached();
    }

    function removeTag(idx, tag) {
        tagsModel.remove(idx)
        tagsField.text = tagsField.text.split(' ').filter(function(_tag) { return _tag && tag !== _tag; }).join(' ') + ' '
    }
}
