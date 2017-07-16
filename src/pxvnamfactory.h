#ifndef PXVNAMFACTORY_H
#define PXVNAMFACTORY_H

#include <QQmlNetworkAccessManagerFactory>

class PxvNAMFactory : public QQmlNetworkAccessManagerFactory
{
public:
    virtual QNetworkAccessManager *create(QObject *parent);
};

#endif // PXVNAMFACTORY_H
