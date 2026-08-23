import QtQuick
import "../"
import prism

StyledRect {
    id: root

    property bool first: false
    property bool last: false

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall
}
