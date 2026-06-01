#include <QDebug>
#include <QNetworkRequest>
#include <QFile>
#include <QFileInfo>
#include <QDir>

#include "utils.h"

PxvRequest::PxvRequest(QObject *parent) : QObject(parent) {}
PxvRequest::~PxvRequest() {
    if (this->qnrq)
        delete this->qnrq;
    if (this->qnr)
        this->qnr->deleteLater();
}

QString PxvRequest::filePath() const {
    return this->path + this->filename;
}

void PxvRequest::get(QNetworkAccessManager &qnam, QString url, QString path, QString filename) {

    // Check path
    QDir dir(path);
    if (!dir.exists()) {
       if (!dir.mkpath(".")) {
           path = "/home/nemo/";
           emit errorMessage("Failed to create directory.", this);
           // TODO system notification
       }
    }
    if (!path.endsWith('/'))
        path.append('/');
    this->path = path;
    this->filename = filename;

    // Check file path
    QFileInfo checkFile(this->filePath());
    if (checkFile.exists()) {
        emit errorMessage("File exits: " + filename, this);
        emit saveImageFailed(this);
        return;
    }

    this->rqurl.setUrl(url);

    this->qnrq = new QNetworkRequest(rqurl);
    if (!this->token.isEmpty()) {
        Utils::setHeaders(*this->qnrq, this->token);
    }
    this->qnr = qnam.get(*qnrq);
    connect(this->qnr, &QNetworkReply::finished, this, &PxvRequest::writeFile);
    connect(this->qnr, &QNetworkReply::downloadProgress, this, &PxvRequest::logProgress);

}

void PxvRequest::setToken(QString token, QString ref_token, int expires_in) {
    this->token = token;
    this->ref_token = ref_token;
    this->expire_time = QTime::currentTime().addSecs(expires_in);
}

void PxvRequest::abort() {
    this->isAborted = true;
    if (this->qnr)
        this->qnr->abort();
}

QString PxvRequest::getFilename() {
    return this->filename;
}

void PxvRequest::writeFile() {
    if (!this->qnr) {
        emit saveImageFailed(this);
        return;
    }
    if (this->qnr->error() != QNetworkReply::NoError) {
        qDebug() << "Error occurred:" << this->qnr->error() << ", url:" << this->rqurl.toString();
        emit errorMessage("Failed to download: " + this->filename, this);
        emit saveImageFailed(this);
        return;
    }
    if (this->isAborted) {
        qDebug() << "Abort writing ...";
        emit saveImageFailed(this);
        return;
    }

    QFile file(this->filePath());
    if (file.open(QIODevice::WriteOnly)) {
        file.write(qnr->readAll());
        file.close();
        emit saveImageSucceeded(this);
    } else {
        qDebug() << this->filename << "failed";
        emit errorMessage("Failed to save file: " + this->filename, this);
        emit saveImageFailed(this);
    }
}

void PxvRequest::logProgress(qint64 received, qint64 total) {
    emit downloadProgress(this->filename, received, total);
}
