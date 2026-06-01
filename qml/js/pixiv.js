.pragma library

.import "pixiv-request.js" as PixivRequest
.import "pixiv-auth.js" as PixivAuth

var app_url_v1 = PixivAuth.appUrlV1
var app_url_v2 = PixivAuth.appUrlV2

var appFilter = "for_ios"

function checkToken(token, context) {
    return PixivRequest.requireToken(token, context)
}

function serialize(params) {
    return PixivRequest.serialize(params)
}

function sendRequest(method, token, url, params, callback) {
    PixivRequest.send(method, token, url, params, callback)
}

function authorizedRequest(method, token, context, url, params, callback) {
    if (!checkToken(token, context)) {
        return
    }

    sendRequest(method, token, url, params, callback)
}

function pageOffset(page) {
    return (page - 1) * 30
}

function withFilter(params) {
    var query = {}
    var source = params || {}

    for (var key in source) {
        if (source.hasOwnProperty(key)) {
            query[key] = source[key]
        }
    }

    query.filter = appFilter
    return query
}

function continueRequest(token, context, url, callback) {
    authorizedRequest("GET", token, context, url, {}, callback)
}

function searchWorks(token, params, page, callback) {
    var searchTargets = {
        tag: "exact_match_for_tags",
        partial_tag: "partial_match_for_tags",
        text: "title_and_caption"
    }

    var query = {
        word: params.q,
        search_target: searchTargets[params.mode] || searchTargets.tag,
        sort: params.sort + "_" + params.order,
        offset: pageOffset(page),
        filter: appFilter
    }

    if (params.period && params.period !== "all") {
        query.duration = params.period
    }
    if (params.start_date) {
        query.start_date = params.start_date
    }
    if (params.end_date) {
        query.end_date = params.end_date
    }

    authorizedRequest("GET", token, "searchWorks", app_url_v1 + "/search/illust", query, callback)
}

function getRankingWork(token, type, mode, page, callback) {
    var query = withFilter({
        mode: mode,
        offset: pageOffset(page)
    })

    if (type === "manga") {
        query.mode = "day_manga"
    }

    authorizedRequest("GET", token, "getRankingWork: " + type + "|" + mode, app_url_v1 + "/illust/ranking", query, callback)
}

function getTrendingTags(token, callback) {
    authorizedRequest("GET", token, "getTrendingTags", app_url_v1 + "/trending-tags/illust", withFilter({}), callback)
}

function getRecommendation(token, page, callback) {
    authorizedRequest("GET", token, "getRecommendation", app_url_v1 + "/illust/recommended", withFilter({
        content_type: "illust",
        include_ranking_label: "true",
        offset: pageOffset(page)
    }), callback)
}

function getRelatedWorks(token, illust_id, seed_ids, page, callback) {
    authorizedRequest("GET", token, "getRelatedWorks", app_url_v2 + "/illust/related", withFilter({
        illust_id: illust_id,
        "seed_illust_ids[]": seed_ids,
        offset: pageOffset(page)
    }), callback)
}

function getFollowingWorks(token, url, params, callback) {
    if (url) {
        continueRequest(token, "getFollowingWorks", url, callback)
        return
    }

    authorizedRequest("GET", token, "getFollowingWorks", app_url_v2 + "/illust/follow", params || {}, callback)
}

function getUserWork(token, user_id, page, callback) {
    authorizedRequest("GET", token, "getUserWork", app_url_v1 + "/user/illusts", withFilter({
        user_id: user_id,
        offset: pageOffset(page)
    }), callback)
}

function getWorkDetails(token, illust_id, callback) {
    authorizedRequest("GET", token, "getWorkDetails", app_url_v1 + "/illust/detail", {
        illust_id: illust_id
    }, callback)
}

function getBookmarkDetail(token, illust_id, callback) {
    authorizedRequest("GET", token, "getBookmarkDetail", app_url_v2 + "/illust/bookmark/detail", {
        illust_id: illust_id
    }, callback)
}

function getUser(token, user_id, callback) {
    authorizedRequest("GET", token, "getUser", app_url_v1 + "/user/detail", withFilter({
        user_id: user_id
    }), callback)
}

function getFollowing(token, user_id, page, callback) {
    authorizedRequest("GET", token, "getFollowing", app_url_v1 + "/user/following", {
        user_id: user_id,
        offset: pageOffset(page),
        restrict: "public"
    }, callback)
}

function getMyFollowing(token, user_id, publicity, page, callback) {
    authorizedRequest("GET", token, "getMyFollowing", app_url_v1 + "/user/following", {
        user_id: user_id,
        offset: pageOffset(page),
        restrict: publicity
    }, callback)
}

function followUser(token, user_id, publicity, callback) {
    authorizedRequest("POST", token, "followUser", app_url_v1 + "/user/follow/add", {
        user_id: user_id,
        restrict: publicity
    }, callback)
}

function unfollowUser(token, user_id, callback) {
    authorizedRequest("POST", token, "unfollowUser", app_url_v1 + "/user/follow/delete", {
        user_id: user_id
    }, callback)
}

function getBookmarks(token, url, params, callback) {
    if (url) {
        continueRequest(token, "getBookmarks", url, callback)
        return
    }

    authorizedRequest("GET", token, "getBookmarks", app_url_v1 + "/user/bookmarks/illust", withFilter(params || {}), callback)
}

function bookmarkWork(token, illust_id, publicity, callback) {
    authorizedRequest("POST", token, "bookmarkWork", app_url_v2 + "/illust/bookmark/add", {
        illust_id: illust_id,
        restrict: publicity
    }, callback)
}

function unbookmarkWork(token, illust_id, callback) {
    authorizedRequest("POST", token, "unbookmarkWork", app_url_v1 + "/illust/bookmark/delete", {
        illust_id: illust_id
    }, callback)
}

function getComments(token, illust_id, callback) {
    authorizedRequest("GET", token, "getComments", app_url_v1 + "/illust/comments", {
        illust_id: illust_id
    }, callback)
}

function login(username, password, callback) {
    PixivAuth.login(username, password, callback)
}

function relogin(refresh_token, callback) {
    PixivAuth.relogin(refresh_token, callback)
}

function authLogin(code, code_verifier, callback) {
    PixivAuth.authLogin(code, code_verifier, callback)
}
