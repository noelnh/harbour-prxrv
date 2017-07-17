#include "pxvnetworkaccessmanager.h"
#include "utils.h"

PxvNetworkAccessManager::PxvNetworkAccessManager(QObject *parent) : QNetworkAccessManager(parent)
{
}

QNetworkReply *PxvNetworkAccessManager::createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData)
{
    QNetworkRequest rqst(request);
    QString url = rqst.url().toString();

    if (url.contains("pximg.net") || url.contains("pixiv.net"))
    {
        Utils::setHeaders(rqst);
    }

    if (url.endsWith(".gif") || url.endsWith(".png") || url.endsWith(".jpg") || url.endsWith(".ico"))
    {
        rqst.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    } else {
        rqst.setAttribute(QNetworkRequest::CacheSaveControlAttribute, false);
    }

    QNetworkReply *reply = QNetworkAccessManager::createRequest(op, rqst, outgoingData);

    return reply;
}
