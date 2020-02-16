#include "requestmgr.h"
#include <unistd.h>
#include <QDebug>

RequestMgr::RequestMgr(QObject *parent) : QObject(parent) {
    qDebug() << "Init mgr ...";
}

void RequestMgr::saveImage(QString token, QString url, QString savePath, QString filename, int isCache) {
    if (url.isEmpty() || savePath.isEmpty() || filename.isEmpty()) {
        emit errorMessage("Invalid request.", nullptr);
        return;
    }

    PxvRequest *pxvRequest = new PxvRequest(this);
    pxvRequest->setToken(token);
    this->prList.append(pxvRequest);

    if (!isCache) {
        connect(pxvRequest, &PxvRequest::saveImageSucceeded, this, &RequestMgr::finishRequest);
        connect(pxvRequest, &PxvRequest::saveImageFailed, this, &RequestMgr::finishRequest);
        connect(pxvRequest, &PxvRequest::errorMessage, this, &RequestMgr::errorMessage);
    } else if (isCache > 1) {
        connect(pxvRequest, &PxvRequest::saveImageSucceeded, this, &RequestMgr::finishCacheRequest);
        connect(pxvRequest, &PxvRequest::saveImageFailed, this, &RequestMgr::finishCacheRequest);
        connect(pxvRequest, &PxvRequest::errorMessage, this, &RequestMgr::ignoreMessage);
    } else {
        connect(pxvRequest, &PxvRequest::saveImageSucceeded, this, &RequestMgr::finishSingleCacheRequest);
    }

    pxvRequest->get(this->qnam, url, savePath, filename);
}

void RequestMgr::saveCaches(QString token, QList<QString> urls, QString savePath) {
    this->cacheCount += urls.length();
    foreach (QString url, urls) {
        QString filename = url.split('/').last();
        this->saveImage(token, url, savePath, filename, 2);
    }
}

void RequestMgr::finishRequest(PxvRequest* pxvRequest) {
    this->prList.removeOne(pxvRequest);
    delete pxvRequest;
    if (this->prList.isEmpty() || this->prList.length() <= this->cacheCount)
        emit allImagesSaved();
}

void RequestMgr::ignoreMessage(QString msg, PxvRequest* pxvRequest) {
    this->finishCacheRequest(pxvRequest);
}

void RequestMgr::finishSingleCacheRequest(PxvRequest* pxvRequest) {
    this->prList.removeOne(pxvRequest);
    delete pxvRequest;
    emit cacheDone();
}

void RequestMgr::finishCacheRequest(PxvRequest* pxvRequest) {
    this->cacheCount -= 1;
    this->prList.removeOne(pxvRequest);
    delete pxvRequest;
    if (this->prList.isEmpty() || this->cacheCount <= 0) {
        this->cacheCount = 0;
        emit allCacheDone();
    }
}

void RequestMgr::cancelRequest(QString filename) {
    for (PxvRequest* pxvRequest : prList) {
        //qDebug() << "Check file:" << pxvRequest->getFilename();
        if (pxvRequest->getFilename() == filename) {
            pxvRequest->abort();
            finishRequest(pxvRequest);
            break;
        }
    }
}

bool RequestMgr::checkFile(QString filePath) {
    return (access(filePath.toStdString().c_str(), F_OK) != -1);
}
