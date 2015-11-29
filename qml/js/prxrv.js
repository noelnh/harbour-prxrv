
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

/*
 * Add activities to activityModel
 * Used as callback in StaccPage and StaccListPage
 */
function addActivities(resp_j) {

    requestLock = false;

    if (!resp_j) return;

    var activities = resp_j['response'];

    if (debugOn) console.log('adding activities to activityModel');
    for (var i in activities) {

        var activityID = parseInt(activities[i]['id']);
        if (activityID < minActivityID)
            minActivityID = activityID;

        var activity_type = activities[i]['type'];
        if (activity_type != 'add_illust' && activity_type != 'add_bookmark') continue;

        var work_id = activities[i]['ref_work']['id'];
        if (illustArray.indexOf(work_id) > -1) {
            if (debugOn) console.log('Already in pool: ' + work_id);
            continue;
        }

        var username = activities[i]['user']['name'];
        var title = activities[i]['ref_work']['title'];

        illustArray.push(work_id);

        activityModel.append({
            workID: work_id,
            title: title,
            headerText: username + ' ' + getActionName(activity_type),
            square128: activities[i]['ref_work']['image_urls']['px_128x128'],
            master480: activities[i]['ref_work']['image_urls']['px_480mw'],
            master240: activities[i]['ref_work']['image_urls']['max_240x240'],
            authorIcon: activities[i]['ref_work']['user']['profile_image_urls']['px_50x50'],
            authorID: activities[i]['ref_work']['user']['id'],
            authorName: activities[i]['ref_work']['user']['name'],
            activityTime: activities[i]['post_time'],
            activityType: activities[i]['type'],
            userIcon: activities[i]['user']['profile_image_urls']['px_50x50'],
            userName: activities[i]['user']['name'],
        });
    }
}

function getCurrentModel() {
    if (currentModel) {
        switch (currentModel[currentModel.length - 1]) {
            case 'favoriteWorkModel':
                if (debugOn) console.log('choose favoriteWorkModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'userWorkModel':
                if (debugOn) console.log('choose userWorkModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'feedsModel':
                if (debugOn) console.log('choose feedsModel');
                return worksModelStack[worksModelStack.length - 1];
            case 'worksSearchModel':
                if (debugOn) console.log('choose worksSearchModel', worksModelStack.length);
                return worksModelStack[worksModelStack.length - 1];
            case 'latestWorkModel':
                if (debugOn) console.log('choose latestWorkModel');
                return latestWorkModel;
            case 'activityModel':
                if (debugOn) console.log('choose activityModel');
                return activityModel;
            case 'rankingWorkModel':
                if (debugOn) console.log('choose rankingWorkModel');
                return rankingWorkModel;
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

function toggleIcon(resp_j) {
    if (debugOn) console.log('index: ', currentIndex);
    if (resp_j['count'] && currentModel[currentModel.length - 1] != "activityModel") {
        if (resp_j['response'][0]['title']) {
            getCurrentModel().setProperty(currentIndex, 'favoriteID', resp_j['response'][0]['favorite_id'])
        } else {
            getCurrentModel().setProperty(currentIndex, 'favoriteID', resp_j['response'][0]['id'])
        }
        if (debugOn) console.log('model fav id: ', getCurrentModel().get(currentIndex).favoriteID);
    } else {
        getCurrentModel().setProperty(currentIndex, 'favoriteID', 0)
    }
}

function toggleBookmarkIcon(workID, favoriteID) {
    if (!loginCheck()) return;
    if (favoriteID) {
        if (debugOn) console.log("bookmark icon off");
        Pixiv.unbookmarkWork(token, favoriteID, toggleIcon);
    } else {
        if (debugOn) console.log("bookmark icon clicked");
        Pixiv.bookmarkWork(token, workID, 'public', toggleIcon);
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

