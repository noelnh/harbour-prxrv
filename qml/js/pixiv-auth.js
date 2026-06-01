.import "pixiv-request.js" as PixivRequest

var appUrlV1 = "https://app-api.pixiv.net/v1"
var appUrlV2 = "https://app-api.pixiv.net/v2"
var authUrl = "https://oauth.secure.pixiv.net/auth/token"

var clientId = "MOBrBDS8blbauoSck0ZfDbtuzpyT"
var clientSecret = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj"
var redirectUri = "https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback"

function login(username, password, callback) {
    PixivRequest.send("POST", "", authUrl, {
        grant_type: "password",
        get_secure_url: 1,
        client_id: clientId,
        client_secret: clientSecret,
        username: username,
        password: password
    }, callback)
}

function relogin(refreshToken, callback) {
    PixivRequest.send("POST", "", authUrl, {
        grant_type: "refresh_token",
        get_secure_url: 1,
        client_id: clientId,
        client_secret: clientSecret,
        refresh_token: refreshToken
    }, callback)
}

function authLogin(code, codeVerifier, callback) {
    PixivRequest.send("POST", "", authUrl, {
        client_id: clientId,
        client_secret: clientSecret,
        code: code,
        code_verifier: codeVerifier,
        grant_type: "authorization_code",
        include_policy: "true",
        redirect_uri: redirectUri
    }, callback)
}
