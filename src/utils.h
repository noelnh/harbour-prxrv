#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QNetworkRequest>

class Utils : public QObject
{
    Q_OBJECT
public:
    explicit Utils(QObject *parent = 0);

public slots:
    QString sha1(const QString & data);
    QString md5(const QString & data);

public:
    static void setHeaders(QNetworkRequest & request, const QString & token = "", bool auth = false);

    Q_INVOKABLE static bool checkBooruInstalled();
};

#endif // UTILS_H
