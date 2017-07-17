#include <QDebug>
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include "utils.h"
#include "pxvimageprovider.h"

PxvImageProvider::PxvImageProvider() : QQuickImageProvider(QQuickImageProvider::Image, QQuickImageProvider::ForceAsynchronousImageLoading)
{
}

QImage PxvImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)


    QStringList s = id.split('#');
    if (s.length() != 2) {
        return QImage();
    }

    const QString token = s.at(0).toLatin1();
    const QString url = s.at(1).toLatin1();

    qDebug() << token << url;

    QImage image;
    QEventLoop loop;
    QNetworkAccessManager mgr;

    QObject::connect(&mgr, &QNetworkAccessManager::finished, [&] (QNetworkReply* reply) {
        if (!reply->error()) {
            image.loadFromData(reply->readAll());
            if (size) {
                *size = image.size();
            }
        }

        loop.quit();
        reply->deleteLater();
    });

    QNetworkRequest request;
    request.setUrl(QUrl(url));

    Utils::setHeaders(request, token);

    mgr.get(request);
    loop.exec();
    return image;
}

