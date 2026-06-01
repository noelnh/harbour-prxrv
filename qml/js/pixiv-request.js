var defaultHeaders = {
    "Referer": "https://app-api.pixiv.net/",
    "App-OS": "ios",
    "App-OS-Version": "14.4",
    "App-Version": "7.6.2",
    "User-Agent": "PixivIOSApp/7.6.2 (iOS 14.4; iPhone9,1)"
}

var requestTimeout = 6000

function requireToken(token, context) {
    if (token === "") {
        console.log("Token is empty for " + context)
        return false
    }
    return true
}

function serialize(params) {
    var query = []
    var source = params || {}

    for (var key in source) {
        if (source.hasOwnProperty(key)) {
            if (source[key] && source[key] instanceof Array) {
                for (var index in source[key]) {
                    query.push(encodeURIComponent(key) + "=" + encodeURIComponent(source[key][index]))
                }
            } else {
                query.push(encodeURIComponent(key) + "=" + encodeURIComponent(source[key]))
            }
        }
    }

    return query.join("&")
}

function setHeaders(xmlhttp, token) {
    for (var key in defaultHeaders) {
        if (defaultHeaders.hasOwnProperty(key)) {
            xmlhttp.setRequestHeader(key, defaultHeaders[key])
        }
    }

    if (token !== "") {
        xmlhttp.setRequestHeader("Authorization", "Bearer " + token)
    }
}

function handleResponse(xmlhttp, token, url, callback) {
    if (token === "" && xmlhttp.status === 400) {
        console.error("Login failed!")
        typeof(callback) === "function" && callback(null)
        return
    }

    if (xmlhttp.status !== 200) {
        console.error("Failed to fetch data from " + url)
        typeof(callback) === "function" && callback(null)
        return
    }

    try {
        var response = JSON.parse(xmlhttp.responseText)
        typeof(callback) === "function" && callback(response)
    } catch (error) {
        console.error("Failed to parse data from " + url + ": " + error)
        typeof(callback) === "function" && callback(null)
    }
}

function send(method, token, url, params, callback) {
    var xmlhttp = new XMLHttpRequest()
    var paramsString = serialize(params)
    var requestUrl = url

    if ((method === "GET" || method === "DELETE") && paramsString !== "") {
        requestUrl += "?" + paramsString
    }

    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState === 4) {
            handleResponse(xmlhttp, token, requestUrl, callback)
        }
    }

    xmlhttp.ontimeout = function() {
        console.error("The request for " + requestUrl + " timed out.")
        typeof(callback) === "function" && callback(null)
    }

    xmlhttp.open(method, requestUrl, true)
    setHeaders(xmlhttp, token)
    xmlhttp.timeout = requestTimeout

    switch (method) {
    case "POST":
        xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        xmlhttp.send(paramsString)
        break
    case "GET":
    case "DELETE":
        xmlhttp.send()
        break
    default:
        console.log("Nothing to send OR not supported method " + method)
    }
}
