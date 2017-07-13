
.pragma library

function getBooruSite(currentSite, attr) {
    var booruSites = [
                {
                    name: 'yandere',
                    rule: /yande.re/,
                    icon: 'https://yande.re/favicon.ico'
                }, {
                    name: 'konachan',
                    rule: /konachan.net/,
                    icon: 'https://konachan.net/favicon.ico'
                },
            ];

    for (var i=0; i<booruSites.length; i++) {
        if (booruSites[i].rule.test(currentSite)) {
            if (attr) return booruSites[i][attr];
            else return booruSites[i];
        }
    }

    return '';
}

function checkSourceSite(currentSite, srcUrl, attr) {
    if (!srcUrl) return '';
    var url = typeof srcUrl === 'string' ? srcUrl : srcUrl.toString();

    var srcSites = [
                {
                    name: 'pixiv',
                    rule: /^https?:\/\/[a-z0-9]+\.((pximg)|(pixiv)).net/,
                    icon: 'https://source.pixiv.net/touch/touch/img/cmn/favicon.ico'
                }, {
                    name: 'nico',
                    rule: /^https?:\/\/seiga.nicovideo.jp/,
                    icon: 'http://seiga.nicovideo.jp/favicon.ico'
                }, {
                    name: 'twitter',
                    rule: /^https?:\/\/((twitter)|(.*\.twimg)).com/,
                    icon: 'https://abs.twimg.com/favicons/favicon.ico'
                }, {
                    name: 'tumblr',
                    rule: /^https?:\/\/[A-Za-z_0-9\-\.]+\.tumblr.com/,
                    icon: 'https://assets.tumblr.com/images/favicons/favicon.ico'
                }, {
                    name: 'deviantart',
                    rule: /^https?:\/\/[A-Za-z_0-9\-]+\.deviantart.((net)|(com))/,
                    icon: 'http://i.deviantart.net/icons/da_favicon.ico'
                }, {
                    name: 'youtube',
                    rule: /^https?:\/\/youtu((\.be)|(be\.com))/,
                    icon: 'https://s.ytimg.com/yts/img/favicon-vflz7uhzw.ico'
                }, {
                    name: 'bcy',
                    rule: /^https?:\/\/bcy.net/,
                    icon: 'https://bcy.net/Public/Image/favicon.ico'
                },
            ];

    for (var i=0; i<srcSites.length; i++) {
        if (srcSites[i].rule.test(url)) {
            if (attr) return srcSites[i][attr];
            else return srcSites[i];
        }
    }

    return getBooruSite(currentSite, attr);
}
