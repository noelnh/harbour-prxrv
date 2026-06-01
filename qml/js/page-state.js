.pragma library

function clearStack(stack) {
    while (stack.length) {
        stack.pop()
    }
}

function clearModel(model) {
    if (model) {
        model.clear()
    }
}

function goHome(pageStack, firstPage, currentModel, worksModelStack) {
    clearStack(currentModel)
    clearStack(worksModelStack)
    pageStack.pop(firstPage)
}

function popWorkModel(currentModel, worksModelStack, expectedModelName) {
    if (currentModel[currentModel.length - 1] !== expectedModelName || !worksModelStack.length) {
        return ""
    }

    worksModelStack.pop()
    return currentModel.pop() || ""
}

function resetSimpleFeed(model) {
    clearModel(model)
    return {
        currentPage: 1
    }
}

function resetPagedFeed(model) {
    clearModel(model)
    return {
        currentPage: 1,
        hiddenWork: 0
    }
}

function resetCursorFeed(model) {
    var state = resetPagedFeed(model)
    state.nextUrl = ""
    return state
}

function resetRankingFeed(model) {
    var state = resetPagedFeed(model)
    state.currentRank = 0
    return state
}

function resetRelatedFeed(model) {
    clearModel(model)
    return {
        currentPage: 1,
        isEmpty: false,
        workIds: {},
        seedIds: []
    }
}
