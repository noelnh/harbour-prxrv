#ifndef CACHEMGR_H
#define CACHEMGR_H

#include <QObject>
#include <QNetworkAccessManager>

class CacheMgr : public QObject
{
    Q_OBJECT

public:
    explicit CacheMgr(QObject *parent = 0);

    void setQNetworkAccessManager(QNetworkAccessManager* qnam);

private:
    quint64 dirSize(const QString & str);
    QString concatPath(const QString & cacheDir, const QString & subDir);
    void clearDir(const QString & path);

signals:

public slots:
    quint64 getSize(const QString & cacheDir, const QString & subDirs = "");
    quint64 clear(const QString & cacheDir, const QString & subDirs = "");

private:
    QNetworkAccessManager* qnam = nullptr;
};

#endif // CACHEMGR_H
