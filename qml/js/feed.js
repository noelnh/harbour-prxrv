.import "prxrv.js" as Prxrv

function shouldHideWork(work, showR18, sanityLevel) {
    return (!showR18 && work["x_restrict"] > 0) || work["sanity_level"] > sanityLevel
}

function detectManga(work, mode) {
    switch (mode) {
    case "type":
        return work["type"] === "manga"
    case "is_manga":
        return work["is_manga"] || false
    case "page_count":
    default:
        return work["page_count"] > 1
    }
}

function getAuthorIcon(work, mode) {
    var profileImageUrls = work["user"]["profile_image_urls"] || {}
    var authorIconMedium = profileImageUrls["medium"] || ""

    if (mode !== "small") {
        return authorIconMedium
    }

    var authorIcon50 = profileImageUrls["px_50x50"]
    if (!authorIcon50 && authorIconMedium) {
        authorIcon50 = authorIconMedium.replace("_170.", "_50.")
    }
    return authorIcon50 || authorIconMedium
}

function buildHeaderText(work, rankHeader, rank) {
    if (rankHeader) {
        return rank + ". " + work["title"]
    }
    return work["title"]
}

function appendWorks(works, model, options) {
    var config = options || {}
    var result = {
        hiddenCount: 0,
        appendedCount: 0,
        currentRank: config.rankStart || 0,
        isEmpty: works.length === 0
    }

    for (var i in works) {
        var work = works[i]
        var workId = work["id"]

        if (config.rankHeader) {
            result.currentRank += 1
        }

        if (config.existingIds) {
            if (workId in config.existingIds) {
                continue
            }
            config.existingIds[workId] = true
        }

        if (config.filterHidden && shouldHideWork(work, config.showR18, config.sanityLevel)) {
            result.hiddenCount += 1
            continue
        }

        var imgUrls = Prxrv.getImgUrls(work)
        model.append({
            workID: workId,
            title: work["title"],
            headerText: buildHeaderText(work, config.rankHeader, result.currentRank),
            square128: imgUrls.square,
            master480: imgUrls.master,
            large: imgUrls.large,
            authorIcon: getAuthorIcon(work, config.authorIconMode),
            authorID: work["user"]["id"],
            authorName: work["user"]["name"],
            authorAccount: work["user"]["account"],
            isManga: detectManga(work, config.mangaMode),
            isBookmarked: work["is_bookmarked"]
        })
        result.appendedCount += 1
    }

    return result
}
