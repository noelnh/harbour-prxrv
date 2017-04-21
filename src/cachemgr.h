#ifndef CACHEMGR_H
#define CACHEMGR_H

#include <QObject>

class CacheMgr : public QObject
{
    Q_OBJECT
public:
    explicit CacheMgr(QObject *parent = 0);

private:
    quint64 dirSize(const QString & str);
    QString concatPath(const QString & cacheDir, const QString & subDirs);
    void clearDir(const QString & path);

signals:

public slots:
    quint64 getSize(const QString & cacheDir, const QString & subdir = "");
    quint64 clear(const QString & cacheDir, const QString & subdir = "");
};

#endif // CACHEMGR_H
