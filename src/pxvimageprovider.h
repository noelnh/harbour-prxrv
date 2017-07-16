#ifndef PXVIMAGEPROVIDER_H
#define PXVIMAGEPROVIDER_H

#include<QQuickImageProvider>

class PxvImageProvider : public QQuickImageProvider
{
public:
    PxvImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
};



#endif // PXVIMAGEPROVIDER_H
