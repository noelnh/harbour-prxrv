import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page

    property string msg: "Coming soon ..."

    SilicaFlickable {
        anchors.fill: parent

        PageHeader {
            id: header
            title: msg
        }
    }
}


