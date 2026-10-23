.pragma library

var _metricsInstance = null

// Qt.createComponent() takes a file URL, not a type name, so build the
// FontMetrics inline. It is shared, so parent it to the top-level item rather
// than to the delegate asking, which can be destroyed while it is cached.
// Measuring goes through advanceWidth(text) rather than TextMetrics, whose
// text/advanceWidth properties would make the calling binding depend on the
// values it writes and loop.
function getMetrics(item) {
    if (!_metricsInstance) {
        var root = item
        while (root && root.parent) root = root.parent
        if (!root || root === item) return null
        _metricsInstance = Qt.createQmlObject("import QtQuick; FontMetrics {}", root)
    }
    return _metricsInstance
}

// Index of the dot that starts the extension, treating compressed tarballs
// (.tar.gz, .tar.zst, ...) as one extension. -1 when there is none to keep.
function extensionIndex(name) {
    var dotIndex = name.lastIndexOf(".")
    if (dotIndex <= 0 || dotIndex === name.length - 1) return -1

    var tarIndex = name.lastIndexOf(".", dotIndex - 1)
    if (tarIndex > 0 && name.substring(tarIndex, dotIndex).toLowerCase() === ".tar") {
        return tarIndex
    }
    return dotIndex
}

function elideFileName(name, elidedText, availableWidth, font) {
    if (!name || availableWidth <= 0) return name || ""

    var metrics = getMetrics(elidedText)
    if (!metrics) return name

    metrics.font = font

    var dotIndex = extensionIndex(name)
    if (dotIndex < 0) {
        return name
    }

    var baseName = name.substring(0, dotIndex)
    var extension = name.substring(dotIndex)

    if (metrics.advanceWidth(name) <= availableWidth) {
        return name
    }

    var ellipsis = "\u2026"
    var availableForBase = availableWidth - metrics.advanceWidth(extension) - metrics.advanceWidth(ellipsis)

    if (availableForBase <= 0) {
        return ellipsis + extension
    }

    var truncatedBase = baseName
    while (truncatedBase.length > 1 && metrics.advanceWidth(truncatedBase) > availableForBase) {
        truncatedBase = truncatedBase.substring(0, truncatedBase.length - 1)
    }

    if (truncatedBase.length === 0) {
        return ellipsis + extension
    }

    return truncatedBase + ellipsis + extension
}

// Text.ElideMiddle is not supported on wrapped, multi-line text: Qt elides the
// end instead, which cuts off the extension. Shorten the base name until it
// fits in `lines` lines of `availableWidth`, keeping the extension visible.
// `measure` is a hidden Text with the label's font and wrap mode.
function elideWrappedFileName(name, measure, availableWidth, lines) {
    if (!name || !measure || availableWidth <= 0) return name || ""

    measure.width = availableWidth
    measure.maximumLineCount = lines
    measure.text = name
    if (!measure.truncated) return name

    var dotIndex = extensionIndex(name)
    if (dotIndex < 0) {
        return name
    }

    var baseName = name.substring(0, dotIndex)
    var extension = name.substring(dotIndex)
    var ellipsis = "\u2026"

    // Longest prefix of the base name that still fits.
    var lo = 0
    var hi = baseName.length - 1
    while (lo < hi) {
        var mid = Math.ceil((lo + hi) / 2)
        measure.text = baseName.substring(0, mid) + ellipsis + extension
        if (measure.truncated) hi = mid - 1
        else lo = mid
    }

    return baseName.substring(0, lo) + ellipsis + extension
}
