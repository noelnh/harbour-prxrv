import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/storage.js" as Storage
import "../js/sites.js" as Sites

Page {
    id: settingsPage

    function updateSites() {
        var sites = Sites.findAll();
        sitesModel.clear();
        for (var i = 0; i < sites.length; i++) {
            sitesModel.append(sites[i]);
            if (debugOn) console.log("Found site:", JSON.stringify(sites[i]));
        }
    }

    ListModel { id: sitesModel }

    Component {
        id: resetDialog
        Dialog {
            Column {
                width: parent.width
                DialogHeader {
                    title: qsTr("Reset database?")
                }
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: leftPadding
                    width: parent.width - 2 * leftPadding
                    text: qsTr("This will remove all sites and accounts!")
                    wrapMode: Text.WordWrap
                }
            }
            onAccepted: {
                Storage.reset();
            }
        }
    }

    Component {
        id: siteRemovalDialog
        Dialog {
            property string domain: ''
            Column {
                width: parent.width
                DialogHeader {
                    title: qsTr("Remove site %1 ?").arg(domain)
                }
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: leftPadding
                    width: parent.width - 2 * leftPadding
                    text: qsTr("This will remove all associated accounts!")
                    wrapMode: Text.WordWrap
                }
            }
            onAccepted: {
                Sites.removeSite(domain);
                updateSites();
            }
        }
    }

    SilicaFlickable {
        id: settingsFlickable

        contentHeight: settingsColumn.height + Theme.paddingLarge
        anchors.fill: parent

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Add Site")
                onClicked: {
                    pageStack.push("SiteDialog.qml")
                }
            }
        }

        PushUpMenu {
            id: pushUpMenu
            MenuItem {
                text: qsTr("Reset Database")
                onClicked: {
                    pageStack.push(resetDialog)
                }
            }
        }

        Column {
            id: settingsColumn
            width: parent.width
            height: childrenRect.height

            PageHeader {
                title: qsTr("Settings")
            }

            SectionHeader {
                text: qsTr("Sites")
            }

            ListView {
                width: parent.width
                height: childrenRect.height
                model: sitesModel
                delegate: ListItem {
                    Label {
                        anchors.centerIn: parent
                        color: Theme.secondaryColor
                        text: name ? name : domain
                    }
                    onClicked: {
                        pageStack.push('SiteDialog.qml', {
                                           siteName: name,
                                           domain: domain,
                                           url: url,
                                           hashString: hash_string
                                       });
                    }
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: pageStack.push(siteRemovalDialog, {domain: domain});
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Bebavior")
            }

            SectionHeader {
                text: qsTr("Downloads")
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            updateSites();
        }
    }

    Component.onCompleted: {
    }
}
