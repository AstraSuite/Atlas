import QtQuick

StyledText {
    property real fill: 0
    property int grade: Colours.light ? 0 : -25
    property font fontStyle: Tokens.font.icon.small
    property int pointSize: 0

    font: Tokens.font.icon.size(pointSize > 0 ? pointSize : fontStyle.pointSize).weight(fontStyle.weight).fill(fill.toFixed(1)).grade(grade).build()
}
