import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    property string url

    property int deltaX: 0
    property int deltaY: 0

    backNavigation: false
    showNavigationIndicator: false
    allowedOrientations: Orientation.All

    function updatePosition() {
        var imgWidth = +img.paintedWidth.toFixed();
        var imgHeight = +img.paintedHeight.toFixed();

        var cw = container.width;
        var ch = container.height;
        var cx = container.x;
        var cy = container.y;
        var scale = container.scale;

        deltaX = (imgWidth * scale - cw) / 2;
        deltaY = (imgHeight * scale - ch) / 2;
        deltaX = +(deltaX < 0 ? 0 : deltaX).toFixed();
        deltaY = +(deltaY < 0 ? 0 : deltaY).toFixed();

        container.x = cx > deltaX ? deltaX : cx < -deltaX ? -deltaX : cx;
        container.y = cy > deltaY ? deltaY : cy < -deltaY ? -deltaY : cy;
    }

    function resetScale() {
        container.scale=1;
        updatePosition();
    }

    Rectangle {
        id: container
        width: parent.width
        height: parent.height
        color: "transparent"

        Image {
            id: img
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            source: url

            onStatusChanged: {
                if(status === Image.Ready ) {
                    updatePosition();
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: img.status === Image.Loading
                size: BusyIndicatorSize.Large
            }
        }

        PinchArea {
            anchors.fill: parent

            pinch.target: container
            pinch.minimumScale: 1
            pinch.maximumScale: 5

            onPinchFinished:  {
                updatePosition();
            }

            MouseArea {
                anchors.fill: parent

                drag.target: container
                drag.minimumX: -deltaX
                drag.maximumX: deltaX
                drag.minimumY: -deltaY
                drag.maximumY: deltaY

                onClicked: {
                    resetScale();
                }

                onPressAndHold: {
                    pageStack.pop();
                }
            }
        }
    }

    onOrientationChanged: {
        resetScale();
    }
}
