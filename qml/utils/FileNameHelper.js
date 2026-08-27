.pragma library

function elideFileName(name, elidedText, availableWidth, font) {
    if (!name || availableWidth <= 0) return name || ""

    var metrics = Qt.createQmlObject('import QtQuick; TextMetrics { font: Tokens.font.body.small }', elidedText)

    var dotIndex = name.lastIndexOf(".")
    if (dotIndex <= 0 || dotIndex === name.length - 1) {
        return name
    }

    var baseName = name.substring(0, dotIndex)
    var extension = name.substring(dotIndex)

    metrics.text = name
    if (metrics.advanceWidth <= availableWidth) {
        metrics.destroy()
        return name
    }

    metrics.text = extension
    var extWidth = metrics.advanceWidth
    var ellipsis = "..."
    metrics.text = ellipsis
    var ellipsisWidth = metrics.advanceWidth
    var availableForBase = availableWidth - extWidth - ellipsisWidth

    if (availableForBase <= 0) {
        metrics.destroy()
        return ellipsis + extension
    }

    var truncatedBase = baseName
    metrics.text = truncatedBase
    while (truncatedBase.length > 1 && metrics.advanceWidth > availableForBase) {
        truncatedBase = truncatedBase.substring(0, truncatedBase.length - 1)
        metrics.text = truncatedBase
    }

    metrics.destroy()

    if (truncatedBase.length === 0) {
        return ellipsis + extension
    }

    return truncatedBase + ellipsis + extension
}
