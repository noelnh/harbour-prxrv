import QtQuick 2.2
import Sailfish.Silica 1.0
import QtWebKit.experimental 1.0

Page {
    property string initUrl: "http://touch.pixiv.net/"
    property bool isAuth: false

    SilicaWebView {
        id: webView

        header: PageHeader {
            title: webView.title
        }

        anchors.fill: parent
        url: initUrl
        experimental.userAgent:  "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.105 Safari/537.36"
        experimental.transparentBackground: true

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

        onLoadingChanged: {
            if (isAuth) {
                if (debugOn) console.log('WebView URL change:', webView.url)
                var url = webView.url.toString() || ''
                if (url.indexOf('pixiv://') === 0) {
                    var match = url.match(/code=([^&]*)/)
                    if (debugOn) console.log('Auth code match:', match && match[1])
                    if (match && match[1]) {
                        authCode(match[1])
                    }
                }
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
