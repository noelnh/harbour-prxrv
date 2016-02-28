import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.contentaction 1.0

Page {
    id: downloadsPage

    SilicaListView {

        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Recent Downloads")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Clear all")
                onClicked: {
                    downloadsModel.clear()
                }
            }
        }

        model: downloadsModel

        delegate: ListItem {
            width: parent.width
            contentHeight: itemName.height + progressBar.height

            menu: ContextMenu {
                MenuItem {
                    visible: finished !== 100
                    text: qsTr("Cancel")
                    onClicked: {
                        requestMgr.cancelRequest(filename)
                        downloadsModel.get(index).finished = 0;
                    }
                }
                MenuItem {
                    text: qsTr("Restart")
                    onClicked: {
                        if (finished !== 100) {
                            requestMgr.cancelRequest(filename)
                        }
                        requestMgr.saveImage(token, source, path, filename)
                    }
                }
                MenuItem {
                    text: qsTr("Remove")
                    onClicked: {
                        if (finished !== 100) {
                            requestMgr.cancelRequest(filename)
                        }
                        downloadsModel.remove(index, 1)
                    }
                }
            }

            Separator {
                width: parent.width
                color: Theme.secondaryColor
            }

            Image {
                id: thumbImage
                height: parent.height
                width: height
                anchors.left: parent.left
                source: thumb
            }

            Label {
                id: itemName
                anchors.left: thumbImage.right
                anchors.leftMargin: Theme.paddingLarge
                text: filename
            }

            ProgressBar {
                id: progressBar
                anchors.left: thumbImage.right
                anchors.leftMargin: -Theme.paddingLarge
                anchors.top: itemName.bottom
                width: parent.width - thumbImage.width + Theme.paddingLarge
                maximumValue: 100
                value: finished
                valueText: value + '%'
            }

            onClicked: {
                if (finished === 100) {
                    var ok = ContentAction.trigger('file://' + path + '/' + filename)
                    if (!ok) {
                        if (debugOn) console.log('Content action error:', ContentAction.error)
                        var errMsg = ''
                        switch (ContentAction.error) {
                            case ContentAction.FileTypeNotSupported:
                                errMsg = qsTr('File type not supported.')
                                break
                            case ContentAction.FileDoesNotExist:
                                errMsg = qsTr('File does not exist.')
                                break
                            case ContentAction.UrlSchemeNotSupported:
                                errMsg = qsTr('Url scheme not supported.')
                                break
                            case ContentAction.InvalidUrl:
                                errMsg = qsTr('Invalid url.')
                                break
                            default:
                                errMsg = qsTr('Unknown error!')
                        }
                        infoBanner.showText(errMsg)
                    }
                } else {
                    infoBanner.showText(qsTr('Downloading ...'))
                }
            }

        }
    }
}
