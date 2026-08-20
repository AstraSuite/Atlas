import QtQuick
import QtQuick.Effects
import "../"

GridView {
    id: root

    property real fadeAmount: 0.12
    property real topFadeOpacity: fadeShouldBeActive(true) ? 0 : 1
    property real bottomFadeOpacity: fadeShouldBeActive(false) ? 0 : 1

    function fadeShouldBeActive(isStart) {
        if (contentHeight <= height)
            return false;

        if (isStart)
            return visibleArea.yPosition > 0.001;
        return visibleArea.yPosition + visibleArea.heightRatio < 0.999;
    }

    boundsBehavior: Flickable.StopAtBounds

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: mask
        maskSpreadAtMin: 0
        maskThresholdMin: 0

        Rectangle {
            id: mask

            anchors.fill: parent
            visible: false
            layer.enabled: true

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, root.topFadeOpacity)
                }
                GradientStop {
                    position: root.fadeAmount
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1 - root.fadeAmount
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
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
