import QtQuick

Item {
    id: root

    readonly property int status: activeLayer === 0 ? imgA.status : imgB.status
    readonly property real actualSize: Math.min(width, height)
    property real implicitSize: 48
    property url source

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property int activeLayer: 0
    property bool initialized: false

    readonly property string targetSourceString: {
        if (!root.source || root.source.toString() === "") return "";
        var src = root.source.toString();
        if (src.startsWith("image://icon/")) {
            var clean = src.split("?")[0];
            return clean + "?v=" + AppController.iconThemeVersion;
        }
        return src;
    }

    onTargetSourceStringChanged: {
        var target = targetSourceString;
        if (target === "") {
            imgA.source = "";
            imgB.source = "";
            imgA.opacity = 0;
            imgB.opacity = 0;
            return;
        }

        if (!initialized) {
            imgA.source = target;
            imgA.opacity = 1.0;
            imgA.scale = 1.0;
            imgB.opacity = 0.0;
            activeLayer = 0;
            initialized = true;
            return;
        }

        if (activeLayer === 0) {
            if (imgA.source.toString() === target) return;
            imgB.scale = 0.92;
            imgB.source = target;
        } else {
            if (imgB.source.toString() === target) return;
            imgA.scale = 0.92;
            imgA.source = target;
        }
    }

    Component.onCompleted: {
        if (targetSourceString !== "" && !initialized) {
            imgA.source = targetSourceString;
            imgA.opacity = 1.0;
            imgA.scale = 1.0;
            imgB.opacity = 0.0;
            activeLayer = 0;
            initialized = true;
        }
    }

    Image {
        id: imgA
        anchors.fill: parent
        cache: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize.width: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        sourceSize.height: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        smooth: true
        mipmap: true
        opacity: 0.0
        scale: 1.0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
                easing: Tokens.anim.standard
            }
        }

        onStatusChanged: {
            if (status === Image.Ready && root.activeLayer === 1 && imgA.source.toString() === root.targetSourceString) {
                imgA.opacity = 1.0;
                imgA.scale = 1.0;
                imgB.opacity = 0.0;
                root.activeLayer = 0;
            }
        }
    }

    Image {
        id: imgB
        anchors.fill: parent
        cache: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize.width: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        sourceSize.height: root.implicitSize > 0 ? Math.min(256, root.implicitSize * 2) : 128
        smooth: true
        mipmap: true
        opacity: 0.0
        scale: 1.0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
                easing: Tokens.anim.standard
            }
        }

        onStatusChanged: {
            if (status === Image.Ready && root.activeLayer === 0 && imgB.source.toString() === root.targetSourceString) {
                imgB.opacity = 1.0;
                imgB.scale = 1.0;
                imgA.opacity = 0.0;
                root.activeLayer = 1;
            }
        }
    }
}
