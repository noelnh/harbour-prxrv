#include <QCryptographicHash>

#include <QDir>

#include "utils.h"

Utils::Utils(QObject *parent) : QObject(parent)
{
}

QString Utils::sha1(const QString & data)
{
    return QString(QCryptographicHash::hash(data.toUtf8(), QCryptographicHash::Sha1).toHex());
}

void Utils::setHeaders(QNetworkRequest & request, const QString & token)
{
    request.setHeader(QNetworkRequest::UserAgentHeader, "PixivIOSApp/6.7.1 (iOS 10.3.1; iPhone8,1)");
    request.setRawHeader("Referer", "https://app-api.pixiv.net/");
    if (!token.isEmpty())
        request.setRawHeader("Authorization", QString("Bearer ").append(token).toStdString().c_str());
}

bool Utils::checkBooruInstalled()
{
    QString mieruPath = "/usr/share/harbour-mieru/qml/pages/MainPage.qml";
    QDir dir(".");
    return dir.exists(mieruPath);
}
