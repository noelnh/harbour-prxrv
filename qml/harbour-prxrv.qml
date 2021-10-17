import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0

import "pages"
import "js/pixiv.js" as Pixiv
import "js/settings.js" as Settings
import "js/accounts.js" as Accounts
import "js/upgrade.js" as Upgrade

ApplicationWindow
{

    property string appName: "harbour-prxrv"

    // Database
    property string dbVersion: checkDbVersion()

    // Settings
    property bool debugOn: Settings.read('debugOn')
    property bool showR18: Settings.read('showR18')
    property int sanityLevel: +(Settings.read('sanityLevel') || '3')
    property string savePath: Settings.read('savePath') || "/home/nemo/Pictures"
    property string cachePath: Settings.read('cachePath') || "/home/nemo/.cache/harbour-prxrv"
    property string customName: Settings.read('customName') || '%i'
    property string codeVerifier: ''

    // Account
    property string token: ''
    property int expireOn: 0
    property var user: currentAccount()

    property string defaultIcon: 'http://source.pixiv.net/common/images/no_profile_s.png'

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
    property bool staccListMode: Settings.read('staccListMode')

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

    property int leftPadding: 25

    // Booru
    property bool booruEnabled: checkBooruEnabled()
    property bool toReloadAccounts: true
    property bool loadSample: false
    property string currentDomain: ''
    property string currentSite: ''
    property string currentUsername: ''
    property string currentPasshash: ''
    property string currentThumb: ''
    property bool openPxvDetails: true


    ListModel { id: accountModel }

    ListModel { id: activityModel }

    ListModel { id: latestWorkModel }

    ListModel { id: recommendationModel }

    ListModel { id: rankingWorkModel }

    ListModel { id: downloadsModel }


    function checkBooruEnabled() {
        return utils.checkBooruInstalled() && Settings.read('booruEnabled');
    }

    function currentAccount() {
        var account = Accounts.current();
        if (account) {
            token = account.token;
            expireOn = parseInt(account.expireOn) || 0;
            return JSON.parse(account.user || '{}');
        }
        return {};
    }

    function checkDbVersion() {
        return Upgrade.upgrade();
    }

    function changeCurrentUser(account) {
        try {
            user = JSON.parse(account.user) || {};
        } catch (err) {
            console.error("Failed to parse user:", err);
            user = {};
        }
        token = account.token || '';
        expireOn = account.expireOn || 0;
    }

    /**
     * Check login
     */
    function loginCheck(accountName) {
        if (debugOn) console.log("login check")

        var account = null;
        var _expireOn = expireOn;

        // Change account
        if (accountName && user['account'] !== accountName) {
            clearCurrentAccount();
            account = Accounts.find("account", accountName);
            _expireOn = account.expireOn || 0;
            changeCurrentUser(account);
        }

        var seconds = new Date().getTime() / 1000

        if (_expireOn < seconds || _expireOn === 0) {
            if (debugOn) console.log("try to re-login ...");

            // Reset token and expireOn
            token = "";
            expireOn = 0;

            // Read account info
            if (!account) {
                if (accountName) {
                    account = Accounts.find("account", accountName);
                } else {
                    account = Accounts.current();
                }
            }

            var username = account.account;
            if (!account || !username) { return false; }

            var refresh_token = account.refreshToken

            // Re-login
            if (!requestLock) {
                requestLock = true
                if (refresh_token) {
                    if (debugOn) console.log("Using refresh_token")
                    Pixiv.relogin(refresh_token, setToken)
                } else {
                    if (debugOn) console.log("Using auth code")
                    startCodeChallenge()
                }
            }
            return false
        }
        return true
    }

    /**
     * Remove account
     */
    function removeAccount(accountName, callback, pop) {
        if (Accounts.remove(accountName)) {
            if (typeof callback === 'function') {
                callback();
            }
            if (accountName === user['account']) {
                user = {};
                token = "";
                expireOn = 0;
            }
            if (pop) {
                pageStack.pop();
            }
        }
    }

    /**
     * Clear current (global) account info
     */
    function clearCurrentAccount() {
        activityModel.clear()
        latestWorkModel.clear()
        recommendationModel.clear()
        user = {}
        token = ""
        expireOn = 0
    }

    /**
     * Get OAuth code
     */
    function startCodeChallenge () {
        var verifier = utils.createVerifier(32, Math.round(Math.random() * 10000))
        var challenge = utils.createChallenge(verifier)
        if (debugOn) console.log('verifier challenge:', verifier, challenge);
        codeVerifier = verifier
        var _props = {"initUrl": "https://app-api.pixiv.net/web/v1/login?code_challenge=" + challenge + "&code_challenge_method=S256&client=pixiv-android", "isAuth": true}
        pageStack.push("pages/WebViewPage.qml", _props)
    }

    /**
     * OAuth login
     */
    function authCode (code) {
        Pixiv.authLogin(code, codeVerifier, function (resp_j) {
            setToken(resp_j, { password: '', remember: true, isActive: true }, true)
        })
    }

    /**
     * Callback to set token and user info to db
     * resp_j: object, response
     * extraOptions: object, {password, remember, isActive}
     * pop: pop pageStack
     */
    function setToken(resp_j, extraOptions, pop) {

        requestLock = false

        if (!resp_j) {
            if (debugOn) console.log("show info")
            infoBanner.showText(qsTr("Login failed!"))
            return
        }

        var resp = resp_j['response']
        var _user = resp['user']
        var _token = resp['access_token']

        //if (debugOn) console.log('New token: ' + _token + '\nuser: ' + _user['account'])

        var seconds = new Date().getTime() / 1000
        var _expireOn = seconds + 3590 | 0

        // Set global properties, except for adding an inactive account
        if (!extraOptions || extraOptions.isActive) {
            user = _user
            token = _token
            expireOn = _expireOn
        }

        var data = {
            token: _token,
            refreshToken: resp['refresh_token'],
            expireOn: _expireOn.toString(),
        }

        Accounts.save(_user, data, extraOptions)

        if (pop)
            pageStack.pop()
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
