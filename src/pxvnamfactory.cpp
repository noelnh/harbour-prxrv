#include "pxvnamfactory.h"
#include "pxvnetworkaccessmanager.h"

QNetworkAccessManager *PxvNAMFactory::create(QObject *parent)
{
    QNetworkAccessManager *nam = new PxvNetworkAccessManager(parent);

    return nam;
}
