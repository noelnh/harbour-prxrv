#ifndef UTILS_H
#define UTILS_H

#include <QObject>

class Utils : public QObject
{
    Q_OBJECT
public:
    explicit Utils(QObject *parent = 0);

public slots:
    QString sha1(const QString & data);
};

#endif // UTILS_H
