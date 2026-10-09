#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QHash>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace atlas::core {

/**
 * Owns the user-rebindable global application shortcuts.
 *
 * The registry of actions (stable id, label, category, icon, default
 * sequences) lives here; the actual behaviour for each action stays in
 * qml/main.qml. Only overrides are persisted (compact JSON under the
 * "shortcuts/bindings" key of QSettings("astra-atlas", "atlas")).
 */
class ShortcutManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Effective bindings for every action: id -> QStringList of portable
    // QKeySequence strings (defaults merged with user overrides).
    Q_PROPERTY(QVariantMap bindings READ bindings NOTIFY shortcutsChanged)
    // Full descriptors for the settings UI: id, label, description, category,
    // icon, sequences, defaults, modified.
    Q_PROPERTY(QVariantList shortcuts READ shortcuts NOTIFY shortcutsChanged)
    // True while the key recorder is open so every AppShortcut is silenced.
    Q_PROPERTY(bool recording READ recording WRITE setRecording NOTIFY recordingChanged)

public:
    static ShortcutManager* instance();
    static ShortcutManager* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    QVariantMap bindings() const;
    QVariantList shortcuts() const;

    bool recording() const { return m_recording; }
    void setRecording(bool rec);

    Q_INVOKABLE QStringList sequencesFor(const QString& id) const;
    Q_INVOKABLE bool hasOverride(const QString& id) const;

    Q_INVOKABLE bool setSequences(const QString& id, const QStringList& seqs);
    Q_INVOKABLE bool addSequence(const QString& id, const QString& seq);
    Q_INVOKABLE bool removeSequence(const QString& id, const QString& seq);
    Q_INVOKABLE void resetAction(const QString& id);
    Q_INVOKABLE void resetAll();

    // Returns [{id, label, sequences}] for every other action already bound to
    // any of the given sequences.
    Q_INVOKABLE QVariantList conflicts(const QString& id, const QStringList& seqs) const;
    // Steal a sequence from all other actions and give it to id.
    Q_INVOKABLE bool reassign(const QString& id, const QString& seq);

    // Convert a Keys.onPressed event into portable shortcut text, or "" when
    // the press cannot be a shortcut (modifier-only, unknown key...).
    Q_INVOKABLE QString sequenceFromKey(int key, int modifiers) const;
    Q_INVOKABLE bool isAcceptable(const QString& seq) const;
    Q_INVOKABLE bool isBareKey(const QString& seq) const;

signals:
    void shortcutsChanged();
    void recordingChanged();

private:
    explicit ShortcutManager(QObject* parent = nullptr);

    struct Action {
        QString id;
        QString label;
        QString description;
        QString category;
        QString icon;
        QStringList defaults;
    };
    static const QList<Action>& defaultActions();
    static const Action* findAction(const QString& id);

    QStringList effectiveSequences(const QString& id) const;
    QStringList canonicalDefaults(const QString& id) const;
    // Store an override without emitting; reverts to "no override" when the
    // list matches the action defaults.
    void applyOverride(const QString& id, const QStringList& seqs);
    void persistOverrides() const;

    QHash<QString, QStringList> m_overrides;
    bool m_recording = false;
};

} // namespace atlas::core