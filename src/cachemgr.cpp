#include <QFileInfo>
#include <QDir>
#include <QList>

#include "cachemgr.h"


CacheMgr::CacheMgr(QObject *parent) : QObject(parent)
{

}

quint64 CacheMgr::getSize(const QString & cacheDir, const QString & subDir) {
    return this->dirSize(this->concatPath(cacheDir, subDir));
}

quint64 CacheMgr::clear(const QString & cacheDir, const QString & subDir) {
    QString path = this->concatPath(cacheDir, subDir);

    QDir dir(path);
    dir.setNameFilters(QStringList() << "*.*");
    dir.setFilter(QDir::Files);
    foreach(QString dirFile, dir.entryList())
    {
        dir.remove(dirFile);
    }

    return this->dirSize(path);
}

QString CacheMgr::concatPath(const QString & cacheDir, const QString & subDir) {
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
                sizex += fileInfo.size();

        }
    }
    return sizex;
}
