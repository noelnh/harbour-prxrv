import QtQuick 2.2
import Sailfish.Silica 1.0

import "../js/prxrv.js" as Prxrv

CoverBackground {

    function setCover(index) {
        if (debugOn) console.log(coverIndex)
        if ( index >= 0 && currentModel.length > 0) {
            var _model = Prxrv.getCurrentModel()
            if (_model && _model.count > 0 && index < _model.count) {
                coverIndex[0] = index
                coverHolder.visible = false
                if (currentModel[currentModel.length-1] === 'downloadsModel') {
                    coverImage.source = _model.get(index).thumb
                    coverTitle.text = _model.get(index).filename
                } else {
                    coverImage.source = _model.get(index).square128
                    coverTitle.text = _model.get(index).title
                }
            }
        }
    }

    CoverPlaceholder {
        id: coverHolder
        visible: !currentThumb
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
        fillMode: Image.PreserveAspectCrop
        source: ""
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if (currentThumb && currentThumb.indexOf('http') === 0) {
                coverImage.source = currentThumb
                coverTitle.text = qsTr("Moebooru")
            } else {
                setCover(coverIndex[0])
            }
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: currentThumb ? '' : setCover(coverIndex[0] > 0 ? coverIndex[0] - 1 : 0 )
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: currentThumb ? '' : setCover(coverIndex[0] + 1)
        }
    }
}


