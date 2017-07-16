#include <QFileInfo>
#include <QDir>
#include <QList>
#include <QAbstractNetworkCache>

#include "cachemgr.h"


CacheMgr::CacheMgr(QObject *parent) : QObject(parent)
{

}

void CacheMgr::setQNetworkAccessManager(QNetworkAccessManager* qnam)
{
    this->qnam = qnam;
}

quint64 CacheMgr::getSize(const QString & cacheDir, const QString & subDirs)
{
    quint64 sizez = 0;

//    FIXME: cacheSize() not update
//    if (this->qnam)
//    {
//        QAbstractNetworkCache* qanc = this->qnam->cache();
//        sizez += qanc->cacheSize();
//    }

    QList<QString> dirs = subDirs.split(',', QString::SkipEmptyParts);

    if (sizez == 0)
        dirs.append("harbour-prxrv");

    if (!dirs.isEmpty())
    {
        foreach (QString dirStr, dirs)
        {
            sizez += this->dirSize(this->concatPath(cacheDir, dirStr));
        }
    }

    return sizez;
}

quint64 CacheMgr::clear(const QString & cacheDir, const QString & subDirs)
{
    quint64 sizez = 0;

    if (!subDirs.isEmpty())
    {
        QList<QString> dirs = subDirs.split(',');
        foreach (QString dirStr, dirs)
        {
            QString path = this->concatPath(cacheDir, dirStr);
            this->clearDir(path);
            sizez += this->dirSize(path);
        }
    }

    if (this->qnam)
    {
        QAbstractNetworkCache* qanc = this->qnam->cache();
        qanc->clear();
        sizez += qanc->cacheSize();
    }

    return sizez;
}

void CacheMgr::clearDir(const QString &path)
{
    QDir dir(path);
    QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::Dirs |  QDir::Hidden | QDir::NoSymLinks | QDir::NoDotAndDotDot);
    foreach (QFileInfo fileInfo, list)
    {
        if(fileInfo.isDir())
        {
            this->clearDir(fileInfo.absoluteFilePath());
        }
        else if (fileInfo.isFile())
        {
            dir.remove(fileInfo.fileName());
        }
    }
}

QString CacheMgr::concatPath(const QString & cacheDir, const QString & subDir)
{
    QString path = cacheDir;
    if (subDir.startsWith('/') || subDir.isEmpty())
        path += subDir;
    else
        path += "/" + subDir;
    return path;
}

quint64 CacheMgr::dirSize(const QString & str)
{
    quint64 sizex = 0;
    QFileInfo str_info(str);
    if (str_info.isDir())
    {
        QDir dir(str);
        QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::Dirs |  QDir::Hidden | QDir::NoSymLinks | QDir::NoDotAndDotDot);
        for (int i = 0; i < list.size(); ++i)
        {
            QFileInfo fileInfo = list.at(i);
            if(fileInfo.isDir())
            {
                sizex += this->dirSize(fileInfo.absoluteFilePath());
            }
            else
            {
                sizex += fileInfo.size();
            }
        }
    }
    return sizex;
}
