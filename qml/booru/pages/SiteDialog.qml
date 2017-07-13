import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/sites.js" as Sites

Dialog {
    id: sitePage

    property string siteName: ''
    property string domain: ''
    property string prot: ''
    property string url: ''
    property string hashString: ''

    SilicaFlickable {
        contentHeight: siteColumn.height + Theme.paddingLarge
        anchors.fill: parent

        Column {
            id: siteColumn
            width: parent.width

            DialogHeader {
                title: domain ? qsTr("Edit Site") : qsTr("New Site")
            }

            TextField {
                id: nameField
                width: parent.width - Theme.paddingLarge
                text: siteName
                label: qsTr("Site name (optional)")
                placeholderText: label
            }

            TextField {
                id: domainField
                readOnly: domain !== ''
                width: parent.width - Theme.paddingLarge
                text: domain
                label: qsTr("Site domain")
                placeholderText: label + ", e.g. yande.re"
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            TextField {
                id: urlField
                width: parent.width - Theme.paddingLarge
                text: prot + domainField.text
                label: qsTr("Site URL")
                placeholderText: "e.g. https://yande.re"
                validator: RegExpValidator { regExp: /https?:\/\/.*[A-z]/ }
                onFocusChanged: {
                    if (text.indexOf('https://') === 0) {
                        prot = "https://"
                    } else if (text.indexOf('http://') === 0) {
                        prot = "http://"
                    }
                }
            }

            TextField {
                id: hashField
                width: parent.width - Theme.paddingLarge
                text: hashString
                label: qsTr("Hash string (optional)")
                placeholderText: "Hash string, e.g. choujin-steiner--your-password--"
            }
        }
    }

    Component.onCompleted: {
        if (!url || url.indexOf('https://') === 0) {
            prot = "https://"
        } else {
            prot = "http://"
        }
        if (url && url !== prot + domain) {
            urlField.text = url
        }
    }

    onAccepted: {
        domain = domainField.text;
        url = urlField.text;
        siteName = nameField.text || domain;
        hashString = hashField.text || 'xyz--your-password--';

        if (domain && url) {
            var result = Sites.addSite(domain, url, siteName, hashString);
            if (debugOn) console.log("add site:", domain, url, siteName, hashString, result);
        }
    }

}
