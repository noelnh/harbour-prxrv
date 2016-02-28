#ifndef REQUESTMGR_H
#define REQUESTMGR_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QList>

#include "pxvrequest.h"

class RequestMgr : public QObject
{
    Q_OBJECT
public:
    explicit RequestMgr(QObject *parent = 0);

signals:
    void downloadProgress(const QString &filename, qint64 received, qint64 total);
    void imageSaved(const QString &filename);
    void allImagesSaved();
    void errorMessage(QString msg);

public slots:
    void saveImage(QString token, QString url, QString savePath, QString filename);
    void finishRequest(PxvRequest*);
    void cancelRequest(QString filename);

private:
    QNetworkAccessManager qnam;
    QList<PxvRequest*> prList;

};

#endif // REQUESTMGR_H
