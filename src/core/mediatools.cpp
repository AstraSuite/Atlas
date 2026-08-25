#include "mediatools.hpp"

#include "fileoperations.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QMimeDatabase>
#include <QProcess>
#include <QStandardPaths>
#include <QtConcurrent>

namespace atlas::core {

namespace {

bool isEven(int v) {
    return v % 2 == 0;
}

int makeEven(int v) {
    return isEven(v) ? v : v - 1;
}

QStringList imageTargetFormats() {
    return { "png", "jpg", "webp", "avif", "bmp", "tiff", "gif" };
}

bool isImageTargetFormat(const QString& format) {
    return imageTargetFormats().contains(format);
}

} // namespace

QStringList MediaTools::audioCodecArgs(const QString& ext) {
    if (ext == QLatin1String("webm") || ext == QLatin1String("opus"))
        return { "-c:a", "libopus", "-b:a", "128k" };
    if (ext == QLatin1String("ogg"))
        return { "-c:a", "libvorbis", "-q:a", "5" };
    if (ext == QLatin1String("mp3"))
        return { "-c:a", "libmp3lame", "-q:a", "2" };
    if (ext == QLatin1String("flac"))
        return { "-c:a", "flac" };
    if (ext == QLatin1String("wav"))
        return { "-c:a", "pcm_s16le" };
    if (ext == QLatin1String("avi"))
        return { "-c:a", "libmp3lame", "-q:a", "2" };
    return { "-c:a", "aac", "-b:a", "192k" };
}

QStringList MediaTools::videoCodecArgs(const QString& ext) {
    if (ext == QLatin1String("webm"))
        return { "-c:v", "libvpx-vp9", "-crf", "34", "-b:v", "0" };
    if (ext == QLatin1String("avi"))
        return { "-c:v", "mpeg4", "-q:v", "4" };
    return { "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-pix_fmt", "yuv420p" };
}

MediaTools* MediaTools::instance() {
    static MediaTools inst;
    return &inst;
}

MediaTools::MediaTools(QObject* parent)
    : QObject(parent) {}

bool MediaTools::ffmpegAvailable() const {
    return !QStandardPaths::findExecutable(QStringLiteral("ffmpeg")).isEmpty();
}

QString MediaTools::imageMagickBinary() {
    static QString cached;
    static QAtomicInt probed{ 0 };
    if (!probed.loadRelaxed()) {
        probed.storeRelaxed(1);
        cached = QStandardPaths::findExecutable(QStringLiteral("magick"));
        if (cached.isEmpty())
            cached = QStandardPaths::findExecutable(QStringLiteral("convert"));
    }
    return cached;
}

bool MediaTools::imageMagickAvailable() const {
    return !imageMagickBinary().isEmpty();
}

bool MediaTools::imageMagickHandles(const QString& source) {
    const QFileInfo fi(source);
    const QString key = fi.suffix().isEmpty()
        ? fi.absoluteFilePath()
        : QStringLiteral(".") + fi.suffix().toLower();

    if (m_imHandleCache.contains(key))
        return m_imHandleCache.value(key);

    bool handled = false;
    const QString magick = imageMagickBinary();
    if (!magick.isEmpty()) {
        bool started = false;
        QProcess proc;
        if (magick.endsWith(QLatin1String("magick"))) {
            // ImageMagick 7: `magick identify -ping <file>`
            proc.start(magick, QStringList{ QStringLiteral("identify"), QStringLiteral("-ping"), source });
            started = true;
        } else {
            // ImageMagick 6: standalone identify binary
            const QString identify = QStandardPaths::findExecutable(QStringLiteral("identify"));
            if (!identify.isEmpty()) {
                proc.start(identify, QStringList{ QStringLiteral("-ping"), source });
                started = true;
            }
        }

        if (started) {
            proc.waitForFinished(3000);
            handled = proc.exitCode() == 0;
        }
    }

    m_imHandleCache.insert(key, handled);
    return handled;
}

void MediaTools::setBusy(bool busy) {
    if (m_busy != busy) {
        m_busy = busy;
        emit busyChanged();
    }
}

void MediaTools::setStatusText(const QString& text) {
    if (m_statusText != text) {
        m_statusText = text;
        emit statusTextChanged();
    }
}

QString MediaTools::uniqueOutputPath(const QString& source, const QString& tag, const QString& ext) {
    const QFileInfo fi(source);
    const QDir dir = fi.absolutePath();
    const QString base = fi.completeBaseName();

    QString candidate = tag.isEmpty()
        ? QString("%1.%2").arg(base, ext)
        : QString("%1 (%2).%3").arg(base, tag, ext);

    int counter = 2;
    while (QFile::exists(dir.filePath(candidate))) {
        candidate = tag.isEmpty()
            ? QString("%1 %2.%3").arg(base, QString::number(counter++), ext)
            : QString("%1 (%2) %3.%4").arg(base, tag, QString::number(counter++), ext);
    }

    return dir.filePath(candidate);
}

int MediaTools::kindFor(const QString& source) {
    if (source.isEmpty() || !QFile::exists(source))
        return static_cast<int>(Unknown);

    QMimeDatabase db;
    const QString mime = db.mimeTypeForFile(source).name();
    if (mime.startsWith(QLatin1String("image/")))
        return static_cast<int>(Image);
    if (mime.startsWith(QLatin1String("video/")))
        return static_cast<int>(Video);
    if (mime.startsWith(QLatin1String("audio/")))
        return static_cast<int>(Audio);
    return static_cast<int>(Unknown);
}

QStringList MediaTools::formatsFor(const QString& source) {
    const Kind kind = static_cast<Kind>(kindFor(source));

    // Don't offer targets whose converting backend is missing
    if ((kind == Video || kind == Audio) && !ffmpegAvailable())
        return {};
    if ((kind == Image || kind == Unknown) && !imageMagickAvailable())
        return {};

    switch (kind) {
    case static_cast<int>(Image):
        return imageTargetFormats();
    case static_cast<int>(Video):
        return { "mp4", "webm", "mkv", "mov", "gif" };
    case static_cast<int>(Audio):
        return { "mp3", "wav", "ogg", "flac", "m4a", "opus" };
    default:
        // Anything else ImageMagick can read (svg, pdf, heic, dds, ...) converts like an image
        return imageMagickHandles(source) ? imageTargetFormats() : QStringList();
    }
}

QString MediaTools::durationFor(const QString& source) {
    const QString ffprobe = QStandardPaths::findExecutable(QStringLiteral("ffprobe"));
    if (ffprobe.isEmpty() || source.isEmpty())
        return {};

    QProcess proc;
    proc.start(ffprobe, QStringList{
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        source });
    proc.waitForFinished(5000);

    bool ok = false;
    const double secs = proc.readAllStandardOutput().trimmed().toDouble(&ok);
    if (!ok || secs <= 0)
        return {};

    const int total = qRound(secs);
    const int h = total / 3600;
    const int m = (total % 3600) / 60;
    const int s = total % 60;

    if (h > 0)
        return QString("%1:%2:%3").arg(h).arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));
    return QString("%1:%2").arg(m).arg(s, 2, 10, QChar('0'));
}

void MediaTools::runProcess(const QString& tool, const QString& description, const QStringList& args, const QString& output) {
    if (m_busy)
        return;

    if (tool.isEmpty()) {
        FileOperations::instance()->addCompletedTask(false, tr("%1 failed - required tool not found").arg(description));
        return;
    }

    setBusy(true);
    setStatusText(description);

    (void)QtConcurrent::run([this, tool, description, args, output]() {
        QProcess proc;
        proc.start(tool, args);
        proc.waitForFinished(-1);
        const bool success = proc.exitCode() == 0 && QFile::exists(output);

        QMetaObject::invokeMethod(this, [this, success, description, output]() {
            setBusy(false);
            setStatusText(QString());
            FileOperations::instance()->addCompletedTask(
                success,
                success ? tr("%1 - saved as %2").arg(description, QFileInfo(output).fileName())
                        : tr("%1 failed").arg(description));
        });
    });
}

void MediaTools::clipVideo(const QString& source, double startSeconds, double endSeconds) {
    if (startSeconds < 0 || endSeconds <= startSeconds) {
        FileOperations::instance()->addCompletedTask(false, tr("Invalid clip range"));
        return;
    }

    const Kind kind = static_cast<Kind>(kindFor(source));
    const QString ext = QFileInfo(source).suffix().toLower();
    const double duration = endSeconds - startSeconds;
    const QString output = uniqueOutputPath(source, QStringLiteral("clipped"), QFileInfo(source).suffix());

    QStringList args;
    args << "-y"
         << "-ss" << QString::number(startSeconds, 'f', 3)
         << "-i" << source
         << "-t" << QString::number(duration, 'f', 3);

    if (kind == Audio)
        args << audioCodecArgs(ext);
    else
        args << videoCodecArgs(ext) << audioCodecArgs(ext);

    args << output;
    runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
               tr("Clipping %1").arg(QFileInfo(source).fileName()), args, output);
}

void MediaTools::convertWithImageMagick(const QString& source, const QString& format) {
    const QString fmt = format.toLower();
    const QString output = uniqueOutputPath(source, QString(), fmt);

    QStringList args;
    args << source;

    if (fmt == QLatin1String("jpg") || fmt == QLatin1String("jpeg")) {
        // JPEG has no alpha channel - flatten transparency onto white
        args << "-background" << "white" << "-alpha" << "remove" << "-quality" << "92";
    } else if (fmt == QLatin1String("webp")) {
        args << "-quality" << "90";
    }

    args << output;
    runProcess(imageMagickBinary(),
               tr("Converting %1 to %2").arg(QFileInfo(source).fileName(), format), args, output);
}

void MediaTools::convertMedia(const QString& source, const QString& format) {
    const Kind kind = static_cast<Kind>(kindFor(source));
    const QString fmt = format.toLower();

    if (kind == Video) {
        const QString output = uniqueOutputPath(source, QString(), fmt);
        QStringList args;
        args << "-y" << "-i" << source;

        if (fmt == QLatin1String("gif"))
            args << "-an" << "-vf" << "fps=12,scale=480:-1:flags=lanczos";
        else
            args << videoCodecArgs(fmt) << audioCodecArgs(fmt);

        args << output;
        runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
                   tr("Converting %1 to %2").arg(QFileInfo(source).fileName(), format), args, output);
        return;
    }

    if (kind == Audio) {
        const QString output = uniqueOutputPath(source, QString(), fmt);
        QStringList args;
        args << "-y" << "-i" << source << "-vn" << audioCodecArgs(fmt) << output;
        runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
                   tr("Converting %1 to %2").arg(QFileInfo(source).fileName(), format), args, output);
        return;
    }

    // Images and anything else ImageMagick can read (svg, pdf, heic, dds, ...)
    if (!imageMagickHandles(source)) {
        FileOperations::instance()->addCompletedTask(false, tr("Unsupported file type for conversion"));
        return;
    }
    if (!imageMagickAvailable()) {
        FileOperations::instance()->addCompletedTask(false, tr("ImageMagick not found - install it to convert images"));
        return;
    }
    convertWithImageMagick(source, fmt);
}

void MediaTools::rotateMedia(const QString& source, int degrees) {
    QString filter;
    if (degrees == 90)
        filter = QStringLiteral("transpose=1");
    else if (degrees == 270 || degrees == -90)
        filter = QStringLiteral("transpose=2");
    else if (degrees == 180)
        filter = QStringLiteral("transpose=1,transpose=1");
    else {
        FileOperations::instance()->addCompletedTask(false, tr("Unsupported rotation angle"));
        return;
    }

    QString ext = QFileInfo(source).suffix().toLower();
    if (ext.isEmpty())
        ext = kindFor(source) == static_cast<int>(Image) ? QStringLiteral("png") : QStringLiteral("mp4");

    const QString output = uniqueOutputPath(source, QStringLiteral("rotated"), ext);
    QStringList args;
    args << "-y" << "-i" << source << "-vf" << filter;

    if (kindFor(source) != static_cast<int>(Image))
        args << videoCodecArgs(ext) << "-an";

    args << output;
    runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
               tr("Rotating %1").arg(QFileInfo(source).fileName()), args, output);
}

void MediaTools::flipMedia(const QString& source, bool horizontal) {
    QString ext = QFileInfo(source).suffix().toLower();
    if (ext.isEmpty())
        ext = kindFor(source) == static_cast<int>(Image) ? QStringLiteral("png") : QStringLiteral("mp4");

    const QString output = uniqueOutputPath(source, horizontal ? QStringLiteral("flipped") : QStringLiteral("mirrored"), ext);
    QStringList args;
    args << "-y" << "-i" << source << "-vf" << (horizontal ? QStringLiteral("hflip") : QStringLiteral("vflip"));

    if (kindFor(source) != static_cast<int>(Image))
        args << videoCodecArgs(ext) << audioCodecArgs(ext);

    args << output;
    runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
               horizontal ? tr("Flipping %1").arg(QFileInfo(source).fileName())
                          : tr("Mirroring %1").arg(QFileInfo(source).fileName()),
               args, output);
}

void MediaTools::circleCrop(const QString& source) {
    const QString output = uniqueOutputPath(source, QStringLiteral("circle"), QStringLiteral("png"));

    QStringList args;
    args << "-y" << "-i" << source << "-vf"
         << "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='255*lt(hypot(X-W/2\\,Y-H/2)\\,min(W,H)/2)'"
         << output;

    runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
               tr("Circle cropping %1").arg(QFileInfo(source).fileName()), args, output);
}

QStringList MediaTools::videoDimensions(const QString& path) {
    const QString ffprobe = QStandardPaths::findExecutable(QStringLiteral("ffprobe"));
    if (ffprobe.isEmpty())
        return {};

    QProcess proc;
    proc.start(ffprobe, QStringList{
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "csv=s=x:p=0",
        path });
    proc.waitForFinished(5000);

    const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    if (!out.contains(QLatin1Char('x')))
        return {};

    const QStringList parts = out.section(QLatin1Char(','), 0, 0).split(QLatin1Char('x'));
    if (parts.size() != 2)
        return {};

    bool wOk = false, hOk = false;
    const int w = parts[0].toInt(&wOk);
    const int h = parts[1].toInt(&hOk);
    if (!wOk || !hOk || w <= 0 || h <= 0)
        return {};

    return { parts[0], parts[1] };
}

void MediaTools::setAspectRatio(const QString& source, int ratioW, int ratioH, bool crop) {
    if (ratioW <= 0 || ratioH <= 0) {
        FileOperations::instance()->addCompletedTask(false, tr("Invalid aspect ratio"));
        return;
    }

    QStringList dims;
    if (kindFor(source) == static_cast<int>(Image)) {
        QImageReader reader(source);
        const QSize size = reader.size();
        if (size.isValid()) {
            dims << QString::number(size.width()) << QString::number(size.height());
        } else {
            dims = videoDimensions(source);
        }
    } else {
        dims = videoDimensions(source);
    }

    if (dims.size() != 2) {
        FileOperations::instance()->addCompletedTask(false, tr("Could not determine media dimensions"));
        return;
    }

    const double iw = dims[0].toDouble();
    const double ih = dims[1].toDouble();
    const double ratio = static_cast<double>(ratioW) / static_cast<double>(ratioH);
    const double srcRatio = iw / ih;

    QString filter;
    if (crop) {
        int cw, ch;
        if (srcRatio > ratio) {
            ch = makeEven(static_cast<int>(ih));
            cw = makeEven(static_cast<int>(ih * ratio));
        } else {
            cw = makeEven(static_cast<int>(iw));
            ch = makeEven(static_cast<int>(iw / ratio));
        }
        filter = QStringLiteral("crop=%1:%2").arg(cw).arg(ch);
    } else {
        int pw, ph;
        if (srcRatio > ratio) {
            ph = makeEven(static_cast<int>(ih));
            pw = makeEven(static_cast<int>(ih * ratio));
        } else {
            pw = makeEven(static_cast<int>(iw));
            ph = makeEven(static_cast<int>(iw / ratio));
        }
        const QString padColor = kindFor(source) == static_cast<int>(Image)
            ? QStringLiteral("black@0.0")
            : QStringLiteral("black");
        filter = QStringLiteral("scale=%1:%2:force_original_aspect_ratio=decrease,pad=%1:%2:(ow-iw)/2:(oh-ih)/2:%3")
                     .arg(pw).arg(ph).arg(padColor);
    }

    const QString tag = crop ? QStringLiteral("cropped") : QStringLiteral("padded");
    QString ext = QFileInfo(source).suffix().toLower();
    if (ext.isEmpty() || kindFor(source) != static_cast<int>(Image))
        ext = kindFor(source) == static_cast<int>(Image) ? QStringLiteral("png") : QStringLiteral("mp4");

    const QString output = uniqueOutputPath(source, tag, ext);
    QStringList args;
    args << "-y" << "-i" << source << "-vf" << filter;

    if (kindFor(source) != static_cast<int>(Image))
        args << videoCodecArgs(ext) << audioCodecArgs(ext);

    args << output;
    runProcess(QStandardPaths::findExecutable(QStringLiteral("ffmpeg")),
               tr("Setting %1 to %2:%3").arg(QFileInfo(source).fileName()).arg(ratioW).arg(ratioH),
               args, output);
}

} // namespace atlas::core
