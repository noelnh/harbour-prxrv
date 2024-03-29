
function getActionType(action_type) {
    switch (action_type) {
        case 'add_bookmark':
            // star, yellow
            return {'type': '\uf005', 'color': '#F8E71C'};
        case 'add_illust':
            // arrow up, blue
            return {'type': '\uf062', 'color': '#69ACC9'};
        case 'add_favorite':
            // plus, green
            return {'type': '\uf067', 'color': '#80B000'};
        default:
            return {'type': action_type, 'color': '#000000'};
    }
}

function getActionName(activity_type) {
    switch (activity_type) {
        case 'add_bookmark':
            return qsTr("add bookmark");
        case 'add_illust':
            return qsTr("add illust");
        case 'add_favorite':
            return qsTr("add favorite");
        default:
            return "";
    }
}


function getCurrentModel() {
    if (currentModel) {
        switch (currentModel[currentModel.length - 1]) {
            case 'followingWorksModel':
                if (debugOn) console.log('choose followingWorksModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'favoriteWorkModel':
                if (debugOn) console.log('choose favoriteWorkModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'userWorkModel':
                if (debugOn) console.log('choose userWorkModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'recommendationModel':
                if (debugOn) console.log('choose recommendationModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'relatedWorksModel':
                if (debugOn) console.log('choose relatedWorksModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'worksSearchModel':
                if (debugOn) console.log('choose worksSearchModel', worksModelStack.length);
                return worksModelStack[worksModelStack.length - 1];
            case 'activityModel':
                if (debugOn) console.log('choose activityModel');
                return activityModel;
            case 'rankingWorkModel':
                if (debugOn) console.log('choose rankingWorkModel');
                return rankingWorkModel;
            case 'downloadsModel':
                if (debugOn) console.log('choose downloadsModel');
                return downloadsModel;
            default:
                if (debugOn) console.log('model null !!!!!');
                return null;
        }
    }
}

function getModelItem(index) {
    var _model = getCurrentModel();
    if (_model) {
        return _model.get(index);
    }
    return _model;
}

function toggleIconOn () {
    if (debugOn) console.log('index: ', currentIndex);
    getCurrentModel().setProperty(currentIndex, 'isBookmarked', true)
}
function toggleIconOff () {
    if (debugOn) console.log('index: ', currentIndex);
    getCurrentModel().setProperty(currentIndex, 'isBookmarked', false)
}
function toggleBookmarkIcon(workID, isAdd) {
    if (!loginCheck()) return;
    if (isAdd) {
        if (debugOn) console.log("bookmark icon clicked", workID);
        Pixiv.bookmarkWork(token, workID, 'public', toggleIconOn);
    } else {
        if (debugOn) console.log("bookmark icon off", workID);
        Pixiv.unbookmarkWork(token, workID, toggleIconOff);
    }
}


function getDuration(time_str) {
    var time = parseInt(time_str);
    var seconds = (Date.now() / 1000 | 0) - time;

    if (seconds < 0) { seconds = 0; }
    if (seconds >= 100) {
        if (seconds >= 60 * 100) {
            if (seconds > 3600 * 24 * 2) {
                if (seconds > 3600 * 24 * 7 * 2) {
                    if (seconds > 3600 * 24 * 30 * 2) {
                        if (seconds > 3600 * 24 * 365 * 2) {
                            return (seconds / (3600 * 24 * 365) | 0) + qsTr(" years");
                        }
                        return (seconds / (3600 * 24 * 30) | 0) + qsTr(" months");
                    }
                    return (seconds / (3600 * 24 * 7) | 0) + qsTr(" weeks");
                }
                return (seconds / (3600 * 24) | 0) + qsTr(" days");
            }
            return (seconds / 3600 | 0) + qsTr(" hours");
        }
        return (seconds / 60 | 0) + qsTr(" minutes");
    }
    return (seconds) + qsTr(" seconds");
}

function paddingZero (num, len) {
    if (!len) {
        len = 2
    }
    return ('000000' + num).substr(-len)
}
function getLocalDatetime (time_str) {
    var d = time_str ? new Date(time_str) : new Date();
    return [d.getFullYear(), paddingZero(d.getMonth() + 1), paddingZero(d.getDate())].join('-') + ' '
            + [paddingZero(d.getHours()), paddingZero(d.getMinutes()), paddingZero(d.getSeconds())].join(':');
}


/**
 * Get image from local cache
 *
 * @param {string} image_url
 * @param {string} subdir
 * @returns {undefined|string}
 */
function getImage(image_url, subdir) {
    if (!subdir) return;
    var imageDirPath = cachePath + '/' + subdir + '/';

    if (Array.isArray(image_url)) {
        return cacheImages(image_url, imageDirPath);
    }

    var idx = image_url.lastIndexOf('/');
    var filename = image_url.substr(idx+1);
    var filePath = imageDirPath + filename;
    if (requestMgr.checkFile(filePath)) {
        if (debugOn) console.log('Found image:' + filePath);
        return filePath;
    }
    requestMgr.saveImage(token, image_url, imageDirPath, filename, 1);
    if (debugOn) console.log('Image not found:' + filename, ', downloading...')
    return '';
}

function cacheImages(image_urls, imageDirPath) {
    if (image_urls.length > 0) {
        var sorted_urls = image_urls.slice().sort();
        for (var i=sorted_urls.length-1; i>0; i--) {
            if (sorted_urls[i] === sorted_urls[i-1])
                sorted_urls.splice(i, 1);
        }
        requestMgr.saveCaches(token, sorted_urls, imageDirPath);
    }
}

function getIcon(icon_url) {
    return getImage(icon_url, 'icons');
}

function getThumb(thumb_url, size) {
    return getImage(thumb_url, 'thumbnails/' + size);
}

function isPixivLink (link) {
    if (!link || (link.indexOf('pixiv.net') < 0 && link.indexOf('pixiv://') < 0)) {
        return false
    }
    var member_id, illust_id
    if (link.indexOf('/users/') > 0) {
        member_id = link.substring(link.indexOf('/users/') + 7)
        return !isNaN(member_id) && [0, member_id]
    } else if (link.indexOf('/illusts/') > 0) {
        illust_id = link.substring(link.indexOf('/illusts/') + 9)
        return !isNaN(illust_id) && [1, illust_id]
    } else if (link.indexOf('/artworks/') > 0) {
        illust_id = link.substring(link.indexOf('/artworks/') + 10)
        return !isNaN(illust_id) && [1, illust_id]
    } else if (link.indexOf('/member.php?id=') > 0) { // Old user url
        member_id = link.substring(link.indexOf('id=') + 3)
        return !isNaN(member_id) && [0, member_id]
    } else if (link.indexOf('illust_id=') > 0) { // Old illust url
        illust_id = link.substring(link.indexOf('_id=') + 4)
        return !isNaN(illust_id) && [1, illust_id]
    }
}

function getImgUrls (work) {
    var square
    var master
    var large
    if (work['image_urls']['px_480mw']) {
        square = work['image_urls']['px_128x128'].replace(/128x128/, '540x540_10_webp')
        master = work['image_urls']['px_480mw'].replace(/480x960/, '600x1200_90_webp')
        large = work['image_urls']['large']
    } else {
        square = work['image_urls']['square_medium']
        master = work['image_urls']['large']
        large = work['meta_single_page'] && work['meta_single_page']['original_image_url']
        if (!large && work['meta_pages'] && work['meta_pages'].length){
            large = work['meta_pages'][0]['image_urls']['original']
        }
    }
    return {
        square: square,
        master: master,
        large: large
    }
}
