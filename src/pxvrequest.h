#ifndef DOWNLOAD_H
#define DOWNLOAD_H

#include <QObject>
#include <QNetworkReply>
#include <QUrl>
#include <QTime>

class QNetworkAccessManager;
class QNetworkRequest;

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
    void errorMessage(QString msg, PxvRequest*);
    void downloadProgress(const QString &filename, qint64 received, qint64 total);

public slots:
    void writeFile();
    void logProgress(qint64, qint64);

private:
    QString token;
    QString ref_token;
    QTime expire_time;

    QString path;
    QString filename;

    QUrl rqurl;
    QNetworkReply* qnr = nullptr;
    QNetworkRequest* qnrq = nullptr;

    bool isAborted = false;
    QString filePath() const;

};

#endif // DOWNLOAD_H
