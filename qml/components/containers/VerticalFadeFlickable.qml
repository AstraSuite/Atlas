import QtQuick
import QtQuick.Effects
import "../"

Flickable {
    id: root

    property real fadeAmount: 0.12
    property real topFadeOpacity: fadeShouldBeActive(true) ? 0 : 1
    property real bottomFadeOpacity: fadeShouldBeActive(false) ? 0 : 1

    function fadeShouldBeActive(isStart) {
        if (contentHeight <= height)
            return false;
        if (isStart)
            return contentY > 2;
        return (contentY + height) < (contentHeight - 2);
    }

    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: maskItem
        maskSpreadAtMin: 0
        maskThresholdMin: 0
    }

    Item {
        id: maskItem
        parent: root
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0, 0, 0, root.topFadeOpacity)
                }
                GradientStop {
                    position: root.fadeAmount
                    color: "black"
                }
                GradientStop {
                    position: 1.0 - root.fadeAmount
                    color: "black"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, root.bottomFadeOpacity)
                }
            }
        }
    }

    Behavior on topFadeOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on bottomFadeOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
