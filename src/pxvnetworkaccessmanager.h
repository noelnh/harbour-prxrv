#ifndef PXVNETWORKACCESSMANAGER_H
#define PXVNETWORKACCESSMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class PxvNetworkAccessManager : public QNetworkAccessManager
{
    Q_OBJECT

public:
    PxvNetworkAccessManager(QObject *parent = 0);

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData);
};

#endif // PXVNETWORKACCESSMANAGER_H
