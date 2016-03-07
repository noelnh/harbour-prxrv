.pragma library

var site = 'https://yande.re/'

function getPosts(limit, page, tags, callback) {
    limit = limit || 50;
    page = page || 1;
    tags = tags || '';
    var params = '?limit=' + limit + '&page=' + page + '&tags=' + tags;

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
    xmlhttp.open('GET', site + 'post.json' + params);
    xmlhttp.send();
}
