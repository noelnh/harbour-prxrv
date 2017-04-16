.pragma library

var site = 'https://yande.re'
var username = 'username'
var passhash = 'passhash'

function sendRequest(method, url, params, data, callback) {

    console.log(method, url, params, data);

    var xmlhttp = new XMLHttpRequest();

    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState === 4) {
            if (xmlhttp.status === 200) {
                console.log('success');
                callback(JSON.parse(xmlhttp.responseText));
            } else {
                console.log('failed');
            }
        }
    }

    if (params) url += '?' + params;

    xmlhttp.open(method, url);
    if (method === 'GET' || method === 'DELETE') {
        xmlhttp.send();
    } else if (method === 'POST') {
        xmlhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
        xmlhttp.send(data);
    }
}

function getPosts(limit, page, tags, callback) {
    limit = limit || 50;
    page = page || 1;
    tags = tags || '';
    var params = 'limit=' + limit + '&page=' + page + '&tags=' + tags;
    var url = site + '/post.json';
    sendRequest('GET', url, params, '', callback);
}

function listFavedUsers(postID, callback) {
    var url = site + '/favorite/list_users.json';
    var params = 'id=' + postID;
    sendRequest('GET', url, params, '', callback);
}

function vote(postID, score, callback) {
    var url = site + "/post/vote.json";
    var params = "login=" + username + "&password_hash=" + passhash;
    var data = "id=" + postID + "&score=" + score;

    sendRequest('POST', url, params, data, callback);
}
