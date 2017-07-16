#include "pxvnetworkaccessmanager.h"

PxvNetworkAccessManager::PxvNetworkAccessManager(QObject *parent) : QNetworkAccessManager(parent)
{
}

QNetworkReply *PxvNetworkAccessManager::createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData)
{
    QNetworkRequest rqst(request);

    rqst.setHeader(QNetworkRequest::UserAgentHeader, "PixivIOSApp/6.0.9 (iOS 9.3.3; iPhone8,1)");
    rqst.setRawHeader("Referer", "http://spapi.pixiv.net/");

    QString url = rqst.url().toString();
    if (url.endsWith(".gif") || url.endsWith(".png") || url.endsWith(".jpg"))
    {
        rqst.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    } else {
        rqst.setAttribute(QNetworkRequest::CacheSaveControlAttribute, false);
    }

    QNetworkReply *reply = QNetworkAccessManager::createRequest(op, rqst, outgoingData);

    return reply;
}
