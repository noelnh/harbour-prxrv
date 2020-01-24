#include <QCryptographicHash>

#include <QDateTime>
#include <QDir>

#include "utils.h"

Utils::Utils(QObject *parent) : QObject(parent)
{
}

QString Utils::sha1(const QString & data)
{
    return QString(QCryptographicHash::hash(data.toUtf8(), QCryptographicHash::Sha1).toHex());
}

QString Utils::md5(const QString & data)
{
    return QString(QCryptographicHash::hash(data.toUtf8(), QCryptographicHash::Md5).toHex());
}

void Utils::setHeaders(QNetworkRequest & request, const QString & token, bool auth)
{
    if (auth) {
        QString dt = QDateTime::currentDateTimeUtc().toString(Qt::ISODate).replace('Z', "+00:00");
        QString hashSecret = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c";
        QString timeMd5 = QString(QCryptographicHash::hash((dt + hashSecret).toUtf8(), QCryptographicHash::Md5).toHex());
        request.setRawHeader("X-Client-Time", dt.toUtf8());
        request.setRawHeader("X-Client-Hash", timeMd5.toUtf8());
    }

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
