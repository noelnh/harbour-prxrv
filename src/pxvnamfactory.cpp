#include <QNetworkDiskCache>
#include <QStandardPaths>
#include <QDir>

#include "pxvnamfactory.h"
#include "pxvnetworkaccessmanager.h"

QNetworkAccessManager *PxvNAMFactory::create(QObject *parent)
{
    QNetworkAccessManager *nam = new PxvNetworkAccessManager(parent);

    QNetworkDiskCache* diskCache = new QNetworkDiskCache(parent);
    QString dataPath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).at(0);
    QDir dir(dataPath);
    if (!dir.exists()) dir.mkpath(dir.absolutePath());

    diskCache->setCacheDirectory(dataPath);
    diskCache->setMaximumCacheSize(300*1024*1024);
    nam->setCache(diskCache);

    return nam;
}
