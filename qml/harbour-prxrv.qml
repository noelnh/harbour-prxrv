import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0

import "pages"
import "js/pixiv.js" as Pixiv
import "js/storage.js" as Storage

ApplicationWindow
{
    // Storage
    property bool debugOn: Storage.readSetting('debugOn') || true
    property var user: JSON.parse(Storage.readSetting('user') || '{}')
    property string token: Storage.readSetting('token')
    property int expireOn: parseInt(Storage.readSetting('expireOn')) || 0
    property bool showR18: Storage.readSetting('showR18')
    property string savePath: Storage.readSetting('savePath') || "/home/nemo/Pictures"
    property string cachePath: Storage.readSetting('cachePath') || "/home/nemo/.cache/harbour-prxrv"
    property string customName: Storage.readSetting('customName') || '%i'

    // String list of models
    property var currentModel: []

    // Stack of worksModels
    property var worksModelStack: []

    // First Page used to pop all
    property var firstPage: null

    property bool requestLock: false

    // Activity
    property var illustArray: []
    property int minActivityID: 0
    property bool staccListMode: Storage.readSetting('staccListMode')

    // LatestWork
    property bool showFollowing: true

    // Cover
    property var coverIndex: [0, ]

    // Details
    /**
     * Trigger to refresh DetailPage when nav back and toggle bookmark
     * Turned true when the bookmark state of fromID work changes in UserWorkPage
     */
    property bool refreshWorkDetails: false


    ListModel { id: activityModel }

    ListModel { id: latestWorkModel }

    ListModel { id: rankingWorkModel }

    ListModel { id: downloadsModel }

    function loginCheck() {
        if (debugOn) console.log("login check")
        var seconds = new Date().getTime() / 1000
        if (expireOn < seconds) {
            token = ""
            var refresh_token = Storage.readSetting("refresh_token")
            if (debugOn) console.log('refresh_token:', refresh_token)
            if (!refresh_token) {
                pageStack.push('SettingsPage.qml')
            } else if (!requestLock) {
                requestLock = true
                if (Storage.readSetting('rememberMe') && user.account) {
                    var passwd = Storage.readSetting('passwd')
                    Pixiv.login(user.account, passwd, setToken)
                } else {
                    Pixiv.relogin(refresh_token, setToken)
                }
            }
            return false
        }
        return true
    }

    function setToken(resp_j) {

        requestLock = false

        if (!resp_j) {
            if (debugOn) console.log("show info")
            infoBanner.showText(qsTr("Login failed!"))
            return
        }

        var resp = resp_j['response']
        user = resp['user']
        token = resp['access_token']
        if (debugOn) console.log('token: ' + token + '\nuser: ' + user['name'])
        Storage.writeSetting('user', JSON.stringify(resp['user']))
        Storage.writeSetting('token', token)
        Storage.writeSetting('refresh_token', resp['refresh_token'])

        var seconds = new Date().getTime() / 1000
        Storage.writeSetting('expireOn', (seconds + 3590 | 0).toString())
        expireOn = seconds + 3590 | 0
    }

    // Update download progress
    function updateProgress(filename, received, total) {
        for (var i = 0; i < downloadsModel.count; i++) {
            if (downloadsModel.get(i).filename === filename) {
                //if (received === total) { }
                downloadsModel.get(i).finished = ~~(received * 100 / total)
                break
            }
        }
    }
    // Downloads notification
    function notifyDownloadsFinished() {
        infoBanner.showText(qsTr("Downloads finished."))
    }
    // Show error message
    function showErrorMessage(msg) {
        infoBanner.showText(msg)
    }

    // Info banner
    Rectangle {
        id: infoBanner
        y: Theme.paddingSmall
        z: 0
        width: parent.width

        height: infoLabel.height + 2 * Theme.paddingMedium
        color: Theme.highlightBackgroundColor
        opacity: 0
        visible: false

        Label {
            id: infoLabel
            text : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            width: parent.width - 2 * Theme.paddingSmall
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            y: Theme.paddingSmall
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAnywhere

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    infoBanner.opacity = 0.0
                    infoBanner.visible = false
                }
            }
        }

        function showText(text) {
            infoLabel.text = text
            opacity = 0.9
            infoBanner.visible = true
            closeTimer.restart()
        }

        function showError(errorMessage) {
            infoLabel.text = errorMessage
            opacity = 0.9
            infoBanner.visible = true
        }

        Behavior on opacity { FadeAnimation {} }

        Timer {
            id: closeTimer
            interval: 3000
            onTriggered: {
                infoBanner.opacity = 0.0
                infoBanner.visible = true
            }
        }
    }


    initialPage: Component { Prxrv { } }

    cover: Qt.resolvedUrl("cover/CoverPage.qml")
}
