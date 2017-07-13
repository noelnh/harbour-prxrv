#include <QCryptographicHash>

#include "utils.h"

Utils::Utils(QObject *parent) : QObject(parent)
{
}

QString Utils::sha1(const QString & data) {
    return QString(QCryptographicHash::hash(data.toUtf8(), QCryptographicHash::Sha1).toHex());
}
