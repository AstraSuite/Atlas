.pragma library

var _metricsComponent = null
var _metricsInstance = null

function getMetrics(parent) {
    if (!_metricsComponent) {
        _metricsComponent = Qt.createComponent("QtQuick.TextMetrics")
    }
    if (!_metricsInstance && _metricsComponent && _metricsComponent.status === 1) {
        _metricsInstance = _metricsComponent.createObject(parent)
    }
    return _metricsInstance
}

function elideFileName(name, elidedText, availableWidth, font) {
    if (!name || availableWidth <= 0) return name || ""

    var metrics = getMetrics(elidedText)
    if (!metrics) return name

    metrics.font = font

    var dotIndex = name.lastIndexOf(".")
    if (dotIndex <= 0 || dotIndex === name.length - 1) {
        return name
    }

    var baseName = name.substring(0, dotIndex)
    var extension = name.substring(dotIndex)

    metrics.text = name
    if (metrics.advanceWidth <= availableWidth) {
        return name
    }

    metrics.text = extension
    var extWidth = metrics.advanceWidth
    var ellipsis = "\u2026"
    metrics.text = ellipsis
    var ellipsisWidth = metrics.advanceWidth
    var availableForBase = availableWidth - extWidth - ellipsisWidth

    if (availableForBase <= 0) {
        return ellipsis + extension
    }

    var truncatedBase = baseName
    metrics.text = truncatedBase
    while (truncatedBase.length > 1 && metrics.advanceWidth > availableForBase) {
        truncatedBase = truncatedBase.substring(0, truncatedBase.length - 1)
        metrics.text = truncatedBase
    }

    if (truncatedBase.length === 0) {
        return ellipsis + extension
    }

    return truncatedBase + ellipsis + extension
}
