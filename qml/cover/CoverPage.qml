import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/prxrv.js" as Prxrv

CoverBackground {

    function setCover(index) {
        if ( index >= 0 && currentModel.length > 0) {
            var _model = Prxrv.getCurrentModel()
            if (_model && _model.count > 0 && index < _model.count) {
                coverIndex = index
                coverHolder.visible = false
                coverImage.source = _model.get(index).square128
                coverTitle.text = _model.get(index).title
            }
        }
    }

    CoverPlaceholder {
        id: coverHolder
        icon.source: "../images/harbour-prxrv.png"
        text: qsTr("Prxrv")
    }

    Label {
        id: coverTitle
        width: parent.width
        anchors.bottom: coverImage.top
        anchors.bottomMargin: Theme.paddingLarge
        horizontalAlignment: Text.AlignHCenter
        elide: TruncationMode.Elide
        text: ""
    }

    Image {
        id: coverImage
        anchors.centerIn: parent
        width: 180
        height: width
        source: ""
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            setCover(coverIndex)
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: setCover(coverIndex - 1)
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: setCover(coverIndex + 1)
        }
    }
}


