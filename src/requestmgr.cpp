#include "requestmgr.h"
#include <QDebug>

RequestMgr::RequestMgr(QObject *parent) : QObject(parent) {
    qDebug() << "Init mgr ...";
}

void RequestMgr::saveImage(QString token, QString url, QString savePath, QString filename) {
    if (token.isEmpty() || url.isEmpty() || savePath.isEmpty() || filename.isEmpty()) {
        emit errorMessage("Invalid request.");
        return;
    }

    PxvRequest *pxvRequest = new PxvRequest(this);
    pxvRequest->setToken(token);
    this->prList.append(pxvRequest);

    connect(pxvRequest, &PxvRequest::saveImageSucceeded, this, &RequestMgr::finishRequest);
    connect(pxvRequest, &PxvRequest::saveImageFailed, this, &RequestMgr::finishRequest);
    connect(pxvRequest, &PxvRequest::errorMessage, this, &RequestMgr::errorMessage);

    pxvRequest->get(this->qnam, url, savePath, filename);
}

void RequestMgr::finishRequest(PxvRequest* pxvRequest) {
    this->prList.removeOne(pxvRequest);
    delete pxvRequest;
    if (this->prList.isEmpty())
        emit allImagesSaved();
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
