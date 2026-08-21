import QtQuick

Item {
    id: root

    readonly property int status: img.status
    readonly property real actualSize: Math.min(width, height)
    property real implicitSize: 48
    property url source

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Image {
        id: img

        anchors.fill: parent
        source: root.source
        cache: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize.width: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        sourceSize.height: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        smooth: true
        mipmap: true
    }
}
