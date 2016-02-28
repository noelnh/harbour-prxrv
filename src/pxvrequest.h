#ifndef DOWNLOAD_H
#define DOWNLOAD_H

#include <QObject>
#include <QNetworkReply>
#include <QUrl>


class PxvRequest : public QObject
{
    Q_OBJECT

public:
    explicit PxvRequest(QObject *parent = 0);
    ~PxvRequest();

    void get(QNetworkAccessManager &qnam, QString url, QString path="/home/nemo/", QString filename="example.jpg");
    void setToken(QString token, QString ref_token="", int expires_in=3600);
    void abort();
    QString getFilename();

signals:
    void saveImageSucceeded(PxvRequest*);
    void saveImageFailed(PxvRequest*);
    void errorMessage(QString msg);

public slots:
    void writeFile();
    void emitFailed(QNetworkReply::NetworkError);
    void logProgress(qint64, qint64);

private:
    QString token;
    QString ref_token;
    QTime expire_time;

    QString path;
    QString filename;

    QUrl rqurl;
    QNetworkReply* qnr;
    QNetworkRequest* qnrq;

    bool isAborted = false;

    void setHeaders();
};

#endif // DOWNLOAD_H
