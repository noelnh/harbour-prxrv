import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: optionsDialog

    property bool _pxvOnly: false
    property bool _pxvDetail: true
    property int _currentPage: 1
    property string _tags: ''

    property int leftPadding: 25

    Column {
        width: parent.width

        DialogHeader {
            title: qsTr("Options")
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
        }

        SectionHeader {
            text: qsTr("Filters")
        }

        TextSwitch {
            id: pxvSwitch
            text: qsTr("Show pixiv works only")
            checked: _pxvOnly
            onCheckedChanged: {
            }
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
            id: pxvDetailSwitch
            text: qsTr("Open pixiv details")
            checked: _pxvDetail
            onCheckedChanged: {
                if (checked != _pxvDetail) {
                    pageStack.previousPage().pxvDetail = checked;
                }
            }
        }

        SectionHeader {
            text: qsTr("Tags")
        }

        BackgroundItem {
            height: Theme.itemSizeSmall
            width: parent.width
            Label {
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: leftPadding
                    verticalCenter: parent.verticalCenter
                }
                text: _tags
            }
            onClicked: {
                if (debugOn) console.log('tag clicked', _tags);
                pageStack.navigateBack();
            }
        }
    }

    onAccepted: {
        var toReload = false;

        var pageNum = pageNumField.text;
        if (pageNum && _currentPage != pageNum) {
            if (pageNum) _currentPage = parseInt(pageNum);
            toReload = true;
        }

        if (pxvSwitch.checked != _pxvOnly) {
            _pxvOnly = pxvSwitch.checked;
            toReload = true;
        }

        if (limitSwitch.checked != showR18) {
            showR18 = limitSwitch.checked;
            toReload = true;
        }

        if (toReload) {
            pageStack.previousPage().reloadPostList(_currentPage, _pxvOnly);
        }

        pageStack.popAttached();
    }
}
