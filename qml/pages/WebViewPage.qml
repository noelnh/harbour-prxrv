import QtQuick 2.2
import Sailfish.Silica 1.0
import QtWebKit.experimental 1.0

Page {
    property string initUrl: "http://touch.pixiv.net/"

    SilicaWebView {
        id: webView

        header: PageHeader {
            title: webView.title
        }

        anchors.fill: parent
        url: initUrl
        experimental.userAgent: "Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25"
        //experimental.userAgent: "Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30    (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"
        //experimental.deviceWidth: 560

        BusyIndicator {
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: webView.loading
        }

        onVerticalVelocityChanged: {
            if (verticalVelocity > 0) {
                panel.open = false
            } else if (verticalVelocity < 0) {
                panel.open = true
            }
        }

    }

    FontLoader {
        source: '../fonts/fontawesome-webfont.ttf'
    }

    DockedPanel {
        id: panel

        width: parent.width
        height: 72

        dock: Dock.Bottom
        open: true

        Row {
            anchors.centerIn: parent
            height: parent.height
            width: parent.width
            Label {
                height: parent.height
                width: parent.width / 3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: 'FontAwesome'
                font.pixelSize: Theme.fontSizeLarge
                text: '\uf060'
                color: webView.canGoBack ? Theme.primaryColor : Theme.secondaryHighlightColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (webView.canGoBack) webView.goBack()
                    }
                }
            }
            Label {
                height: parent.height
                width: parent.width / 3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: 'FontAwesome'
                font.pixelSize: Theme.fontSizeLarge
                text: webView.loading ? '\uf00d' : '\uf021'
                color: Theme.primaryColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        webView.loading ? webView.stop() : webView.reload()
                    }
                }
            }
            Label {
                height: parent.height
                width: parent.width / 3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: 'FontAwesome'
                font.pixelSize: Theme.fontSizeLarge
                text: '\uf061'
                color: webView.canGoForward ? Theme.primaryColor : Theme.secondaryHighlightColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (webView.canGoForward) webView.goForward()
                    }
                }
            }
        }
    }
}
