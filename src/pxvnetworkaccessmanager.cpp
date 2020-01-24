#include "pxvnetworkaccessmanager.h"
#include "utils.h"

PxvNetworkAccessManager::PxvNetworkAccessManager(QObject *parent) : QNetworkAccessManager(parent)
{
}

QNetworkReply *PxvNetworkAccessManager::createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData)
{
    QNetworkRequest rqst(request);
    QString url = rqst.url().toString();

    if (url.contains("oauth.secure."))
    {
        Utils::setHeaders(rqst, "", true);
    }
    else if (url.contains("pximg.net") || url.contains("pixiv.net"))
    {
        Utils::setHeaders(rqst);
    }

    if (checkCacheRule(url))
    {
        rqst.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    } else {
        rqst.setAttribute(QNetworkRequest::CacheSaveControlAttribute, false);
    }

    QNetworkReply *reply = QNetworkAccessManager::createRequest(op, rqst, outgoingData);

    return reply;
}

bool PxvNetworkAccessManager::checkCacheRule(const QString &url) {
    return url.endsWith(".ico") || url.endsWith(".gif") || url.endsWith(".jpeg") ||
                    url.endsWith(".png") || url.endsWith(".jpg") ||
                    url.contains("/tag.json?cache=1&");
}
