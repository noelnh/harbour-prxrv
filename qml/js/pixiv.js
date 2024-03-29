.pragma library

var base_url = 'https://public-api.secure.pixiv.net/v1'
var app_url_v1 = 'https://app-api.pixiv.net/v1'
var app_url_v2 = 'https://app-api.pixiv.net/v2'
var client_id = 'MOBrBDS8blbauoSck0ZfDbtuzpyT'
var client_secret = 'lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj'
var redirect_uri = "https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback"
var auth_url = 'https://oauth.secure.pixiv.net/auth/token'

function checkToken(token, msg) {
    //console.log('Token for ' + msg + '(): ' + token);
    if (token == '') {
        console.log('Token is empty');
        return false;
    }
    return true;
}

function serialize(obj) {
    var str = [];
    for (var p in obj) {
        if (obj.hasOwnProperty(p)) {
            if (obj[p] && obj[p] instanceof Array) {
                for (var i in obj[p]) {
                    str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p][i]));
                }
            } else {
                str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
            }
        }
    }
    return str.join("&");
}

function sendRequest(method, token, url, params, callback) {

    var xmlhttp = new XMLHttpRequest();

    var params_str = serialize(params)

    xmlhttp.onreadystatechange = function() {
        console.log('http ready: ' + xmlhttp.readyState);
        if (xmlhttp.readyState == 4) {
            console.log('http status: ' + xmlhttp.status);
            if (token == '' && xmlhttp.status == 400) {
                console.error('Login failed!');
                typeof(callback) === 'function' && callback(null);
            } else if (xmlhttp.status == 200) {
                var resp_j = JSON.parse(xmlhttp.responseText);
                //console.log('resp_j', JSON.stringify(resp_j))
                if (token == '' || resp_j) {
                    typeof(callback) === 'function' && callback(resp_j);
                }
            } else { // if (xmlhttp.status == 0) {   // or 404
                console.error('Failed to fetch data from ' + url);
                typeof(callback) === 'function' && callback(null);
            }
        }
    }

    xmlhttp.ontimeout = function() {
        console.error('The request for ' + url + ' timed out.');
        typeof(callback) === 'function' && callback(null);
    };

    if ((method == 'GET' || method == 'DELETE') && params_str != '') url += '?' + params_str;

    var headers = {
        'Referer': 'https://app-api.pixiv.net/',
        'App-OS': 'ios',
        'App-OS-Version': '14.4',
        'App-Version': '7.6.2',
        'User-Agent': 'PixivIOSApp/7.6.2 (iOS 14.4; iPhone9,1)',
    }

    xmlhttp.open(method, url, true);
    for (var key in headers) {
        xmlhttp.setRequestHeader(key, headers[key]);
    }
    if (token !== '') xmlhttp.setRequestHeader('Authorization', 'Bearer ' + token);

    // TODO
    xmlhttp.timeout = 6000;

    switch (method) {
        case 'POST':
            xmlhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xmlhttp.send(params_str);
            break;
        case 'GET':
        case 'DELETE':
            xmlhttp.send();
            break;
        default:
            console.log("Nothing to send OR not supported method " + method);
    }
}


// Search
//
// params: q, mode, sort, order, period, start_date, end_date
//
//     mode: tag, partial_tag, text
//     sort: date, popular
//     order: desc, asc
//     period: day, week, month, all
//
// sort-by-popular only works with 'desc' order,
// and returns at most 20 items for non-premium user
//
function searchWorks(token, params, page, callback) {
    if (!checkToken(token, 'search')) return;

    var url = app_url_v1 + '/search/illust'
    var searchTargets = {tag: 'exact_match_for_tags', partial_tag: 'partial_match_for_tags', text: 'title_and_caption'}

    var query = {
        word: params.q,
        search_target: searchTargets[params.mode] || searchTargets.tag,
        sort: params.sort + '_' + params.order,
        offset: (page - 1) * 30,
        filter: 'for_ios',
    }
    if (params.period && params.period !== 'all') {
        query.duration = params.period
    }
    if (params.start_date) {
        query.start_date = params.start_date;
    }
    if (params.end_date) {
        query.end_date = params.end_date;
    }

    sendRequest('GET', token, url, query, callback);
}


// Ranking
// TODO params.date
//
function getRankingWork(token, type, mode, page, callback) {
    if (!checkToken(token, 'getRankingWork: ' + type + '|' + mode)) return;
    var url = app_url_v1 + '/illust/ranking';
    var params = {
        'mode': mode,
        'offset': (page - 1) * 30,
        'filter': 'for_ios',
    };
    if (type === 'manga') {
        params.mode = 'day_manga'
    }

    sendRequest('GET', token, url, params, callback);
}


// Trending tags (App API)
//
function getTrendingTags(token, callback) {
    if (!checkToken(token, 'getTrendingTags')) return;
    var url = app_url_v1 + '/trending-tags/illust';
    var params = {
        'filter': 'for_ios',
    };
    sendRequest('GET', token, url, params, callback);
}


// Recommendation (App API)
//
function getRecommendation(token, page, callback) {
    if (!checkToken(token, 'getRecommendation')) return;
    var url = app_url_v1 + '/illust/recommended';
    var params = {
        'content_type': 'illust',
        'include_ranking_label': 'true',
        'filter': 'for_ios',
        'offset': (page-1) * 30,
    };
    sendRequest('GET', token, url, params, callback);
}


// Related works (App API)
//
function getRelatedWorks(token, illust_id, seed_ids, page, callback) {
    if (!checkToken(token, 'getRelatedWorks')) return;
    var url = app_url_v2 + '/illust/related';
    var params = {
        'illust_id': illust_id,
        'filter': 'for_ios',
        'seed_illust_ids[]': seed_ids,
        'offset': (page-1) * 30,
    };
    sendRequest('GET', token, url, params, callback);
}

// Following works (App API)
//
function getFollowingWorks(token, url, params, callback) {
    if (!checkToken(token, 'getFollowingWorks')) return;
    if (!url) {
        url = app_url_v2 + '/illust/follow'
        sendRequest('GET', token, url, params, callback);
    } else {
        sendRequest('GET', token, url, {}, callback);
    }
}


// User Works
//
function getUserWork(token, user_id, page, callback) {
    if (!checkToken(token, 'getUserWork')) return;
    var url = app_url_v1 + '/user/illusts';
    var params = {
        user_id: user_id,
        offset: (page-1) * 30,
        filter: 'for_ios',
    };
    // TODO type: illust, manga
    sendRequest('GET', token, url, params, callback);
}


// Work Details
//
function getWorkDetails(token, illust_id, callback) {
    if (!checkToken(token, 'getWorkDetails2')) return;
    var url = app_url_v1 + '/illust/detail';
    var params = {
        'illust_id': illust_id
    }
    sendRequest('GET', token, url, params, callback);
}

// Bookmark Detail
//
function getBookmarkDetail(token, illust_id, callback) {
    if (!checkToken(token, 'getWorkDetails2')) return;
    var url = app_url_v2 + '/illust/bookmark/detail';
    var params = {
        'illust_id': illust_id
    }
    sendRequest('GET', token, url, params, callback);
}

// User Details
//
function getUser(token, user_id, callback) {
    if (!checkToken(token, 'getUser')) return;
    var url = app_url_v1 + '/user/detail';
    var params = {
        user_id: user_id,
        filter: 'for_ios',
    };
    sendRequest('GET', token, url, params, callback);
}


// Following User
//
function getFollowing(token, user_id, page, callback) {
    if (!checkToken(token, 'getFollowing')) return;
    var url = app_url_v1 + '/user/following';
    var params = {
        user_id: user_id,
        offset: (page-1) * 30,
        restrict: 'public',
    };
    sendRequest('GET', token, url, params, callback);
}

function getMyFollowing(token, user_id, publicity, page, callback) {
    if (!checkToken(token, 'getMyFollowing')) return;
    var url = app_url_v1 + '/user/following';
    var params = {
        user_id: user_id,
        offset: (page-1) * 30,
        restrict: publicity,
    };
    sendRequest('GET', token, url, params, callback);
}

function followUser(token, user_id, publicity, callback) {
    if (!checkToken(token, 'followUser')) return;
    var url = app_url_v1 + '/user/follow/add';
    var postdata = {
        'user_id': user_id,
        'restrict': publicity
    };
    sendRequest('POST', token, url, postdata, callback);
}

function unfollowUser(token, user_id, callback) {
    if (!checkToken(token, 'unfollowUser')) return;
    var url = app_url_v1 + '/user/follow/delete';
    var params = {
        'user_id': user_id,
    };
    sendRequest('POST', token, url, params, callback);
}


// Bookmark Work
//
function getBookmarks(token, url, params, callback) {
    if (!url) {
        url = app_url_v1 + '/user/bookmarks/illust'
        params['filter'] = 'for_ios'
        sendRequest('GET', token, url, params, callback);
    } else {
        sendRequest('GET', token, url, {}, callback);
    }
}

function bookmarkWork(token, illust_id, publicity, callback) {
    if (!checkToken(token, 'bookmarkWork')) return;
    var url = app_url_v2 + '/illust/bookmark/add';
    var postdata = {
        'illust_id': illust_id,
        'restrict': publicity
        // 'tags': 'TODO'
    };
    sendRequest('POST', token, url, postdata, callback);
}

function unbookmarkWork(token, illust_id, callback) {
    if (!checkToken(token, 'unbookmarkWork')) return;
    var url = app_url_v1 + '/illust/bookmark/delete';
    var postdata = {
        'illust_id': illust_id
    };
    sendRequest('POST', token, url, postdata, callback);
}

function getComments(token, illust_id) {
    if (!checkToken(token, 'getComments')) return;
    var url = app_url_v1 + '/illust/comments';
    var params = {
        'illust_id': illust_id
    }
    sendRequest('GET', token, url, params, callback);
}


// Login
//
function login(username, password, callback) {
    var url = auth_url
    var postdata = {
        'grant_type': 'password',
        'get_secure_url': 1,
        'client_id': client_id,
        'client_secret': client_secret,
        'username': username,
        'password': password,
    };
    sendRequest('POST', '', url, postdata, callback);
}

function relogin(refresh_token, callback) {
    var url = auth_url
    var postdata = {
        'grant_type': 'refresh_token',
        'get_secure_url': 1,
        'client_id': client_id,
        'client_secret': client_secret,
        'refresh_token': refresh_token,
    };
    sendRequest('POST', '', url, postdata, callback);
}

function authLogin (code, code_verifier, callback) {
    var url = auth_url
    var postdata={
        "client_id": client_id,
        "client_secret": client_secret,
        "code": code,
        "code_verifier": code_verifier,
        "grant_type": "authorization_code",
        "include_policy": "true",
        "redirect_uri": redirect_uri,
    }
    sendRequest('POST', '', url, postdata, callback);
}
