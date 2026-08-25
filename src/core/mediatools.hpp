#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QHash>
#include <QJSEngine>
#include <QQmlEngine>
#include <qqmlintegration.h>

namespace atlas::core {

class MediaTools : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(bool ffmpegAvailable READ ffmpegAvailable CONSTANT)
    Q_PROPERTY(bool imageMagickAvailable READ imageMagickAvailable CONSTANT)

public:
    static MediaTools* instance();
    static MediaTools* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    bool busy() const { return m_busy; }
    QString statusText() const { return m_statusText; }
    bool ffmpegAvailable() const;
    bool imageMagickAvailable() const;

    enum Kind {
        Image,
        Video,
        Audio,
        Unknown
    };
    Q_ENUM(Kind)

    Q_INVOKABLE void clipVideo(const QString& source, double startSeconds, double endSeconds);
    Q_INVOKABLE void convertMedia(const QString& source, const QString& format);
    Q_INVOKABLE void rotateMedia(const QString& source, int degrees);
    Q_INVOKABLE void flipMedia(const QString& source, bool horizontal);
    Q_INVOKABLE void circleCrop(const QString& source);
    Q_INVOKABLE void setAspectRatio(const QString& source, int ratioW, int ratioH, bool crop);

    Q_INVOKABLE static int kindFor(const QString& source);
    Q_INVOKABLE QStringList formatsFor(const QString& source);
    Q_INVOKABLE static QString durationFor(const QString& source);

signals:
    void busyChanged();
    void statusTextChanged();

private:
    explicit MediaTools(QObject* parent = nullptr);

    void setBusy(bool busy);
    void setStatusText(const QString& text);
    void runProcess(const QString& tool, const QString& description, const QStringList& args, const QString& output);

    static QString uniqueOutputPath(const QString& source, const QString& tag, const QString& ext);
    static QStringList videoDimensions(const QString& path);
    static QStringList audioCodecArgs(const QString& ext);
    static QStringList videoCodecArgs(const QString& ext);

    static QString imageMagickBinary();
    bool imageMagickHandles(const QString& source);
    void convertWithImageMagick(const QString& source, const QString& format);

    bool m_busy = false;
    QString m_statusText;
    QHash<QString, bool> m_imHandleCache;
};

} // namespace atlas::core
