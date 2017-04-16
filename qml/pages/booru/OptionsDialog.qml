import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: optionsDialog

    property bool _pxvOnly: false
    property int _currentPage: 1

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
