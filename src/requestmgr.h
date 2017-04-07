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
    void errorMessage(QString msg, PxvRequest*);
    void cacheDone();
    void allCacheDone();

public slots:
    void saveImage(QString token, QString url, QString savePath, QString filename, int isCache=0);
    void saveCaches(QString token, QList<QString> urls, QString savePath);
    void finishRequest(PxvRequest*);
    void finishSingleCacheRequest(PxvRequest*);
    void finishCacheRequest(PxvRequest*);
    void ignoreMessage(QString msg, PxvRequest*);
    void cancelRequest(QString filename);
    bool checkFile(QString filePath);

private:
    QNetworkAccessManager qnam;
    QList<PxvRequest*> prList;
    int cacheCount = 0;
};

#endif // REQUESTMGR_H
