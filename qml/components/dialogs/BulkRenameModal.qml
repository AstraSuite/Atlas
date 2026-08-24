import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import "../controls"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property var targets: []
    property var fileItems: []

    // Renamer Mode: "replace", "number", "insert", "remove", "case", "date"
    property string mode: "replace"
    readonly property var modeNames: ["replace", "number", "insert", "remove", "case", "date"]
    readonly property int modeIndex: Math.max(0, modeNames.indexOf(mode))

    // Target Scope: 0 = Name only, 1 = Extension only, 2 = Name and extension
    property int targetScope: 0

    // Mode 1: Search & Replace
    property string findText: ""
    property string replaceText: ""
    property bool caseSensitive: false
    property bool useRegex: false

    // Mode 2: Numbering
    property int numberStyle: 1 // 0: 1 2 3, 1: 01 02, 2: 001 002, 3: 0001, 4: a b c, 5: A B C, 6: i ii iii, 7: I II III
    property int numberTextMode: 0 // 0: Text - Number, 1: Number - Text, 2: Custom Pattern
    property string numberPrefixText: "_"
    property string numberCustomPattern: "#{name}"
    property int startAt: 1
    property int stepBy: 1

    // Mode 3: Insert / Overwrite
    property string insertText: ""
    property int insertPosition: 0
    property int insertOffsetMode: 0 // 0: From Left (Start), 1: From Right (End)
    property int insertAction: 0 // 0: Insert, 1: Overwrite

    // Mode 4: Remove Characters
    property int removeStart: 0
    property int removeCount: 1
    property int removeOffsetMode: 0 // 0: From Left (Start), 1: From Right (End)

    // Mode 5: Change Case
    property int caseMode: 0 // 0: Lowercase, 1: Uppercase, 2: Title Case, 3: First letter uppercase, 4: CamelCase, 5: kebab-case, 6: snake_case

    // Mode 6: Insert Date / Time
    property int dateSource: 0 // 0: Current Time, 1: Modification Time, 2: Creation Time, 3: Access Time
    property int dateFormat: 0 // 0: YYYY-MM-DD, 1: YYYYMMDD, 2: YYYY-MM-DD_hh-mm-ss, 3: YYYYMMDD_hhmmss, 4: Custom
    property string customDateFormat: "yyyy-MM-dd"
    property int datePlacement: 0 // 0: Prefix (Start), 1: Suffix (End), 2: Overwrite
    property string dateSeparator: "_"

    signal applied(var paths, var names)

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    onWheel: wheel => wheel.accepted = true
    Keys.onEscapePressed: root.expanded = false

    onExpandedChanged: {
        if (expanded) {
            root.fileItems = (root.targets || []).map(t => ({
                path: t.path || "",
                name: t.name || "",
                isDir: !!t.isDir,
                modified: t.modified || Date.now(),
                created: t.created || Date.now(),
                accessed: t.accessed || Date.now()
            }));
            root.findText = "";
            root.replaceText = "";
            root.insertText = "";
            root.numberPrefixText = "_";
            root.startAt = 1;
            root.stepBy = 1;
        } else if (typeof splitContainer !== "undefined" && splitContainer) {
            splitContainer.focusActiveView();
        }
    }

    // Helper: Roman Numerals
    function toRoman(num, upper) {
        if (num <= 0) return String(num);
        const lookup = [
            { v: 1000, s: "M" }, { v: 900, s: "CM" }, { v: 500, s: "D" }, { v: 400, s: "CD" },
            { v: 100, s: "C" }, { v: 90, s: "XC" }, { v: 50, s: "L" }, { v: 40, s: "XL" },
            { v: 10, s: "X" }, { v: 9, s: "IX" }, { v: 5, s: "V" }, { v: 4, s: "IV" }, { v: 1, s: "I" }
        ];
        let roman = "";
        let n = num;
        for (let i = 0; i < lookup.length; i++) {
            while (n >= lookup[i].v) {
                roman += lookup[i].s;
                n -= lookup[i].v;
            }
        }
        return upper ? roman : roman.toLowerCase();
    }

    // Helper: Generate formatted number string
    function formatNumberString(index) {
        const val = root.startAt + index * Math.max(1, root.stepBy);
        switch (root.numberStyle) {
            case 0: return String(val); // 1, 2, 3...
            case 1: return String(val).padStart(2, "0"); // 01, 02...
            case 2: return String(val).padStart(3, "0"); // 001, 002...
            case 3: return String(val).padStart(4, "0"); // 0001, 0002...
            case 4: return String.fromCharCode(97 + ((val - 1) % 26)); // a, b, c...
            case 5: return String.fromCharCode(65 + ((val - 1) % 26)); // A, B, C...
            case 6: return toRoman(val, false); // i, ii, iii...
            case 7: return toRoman(val, true); // I, II, III...
            default: return String(val);
        }
    }

    // Helper: Format Date / Time string
    function formatDateString(timestamp) {
        const d = new Date(timestamp);
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, "0");
        const dd = String(d.getDate()).padStart(2, "0");
        const hh = String(d.getHours()).padStart(2, "0");
        const min = String(d.getMinutes()).padStart(2, "0");
        const ss = String(d.getSeconds()).padStart(2, "0");

        switch (root.dateFormat) {
            case 0: return `${yyyy}-${mm}-${dd}`;
            case 1: return `${yyyy}${mm}${dd}`;
            case 2: return `${yyyy}-${mm}-${dd}_${hh}-${min}-${ss}`;
            case 3: return `${yyyy}${mm}${dd}_${hh}${min}${ss}`;
            case 4: {
                let fmt = root.customDateFormat || "yyyy-MM-dd";
                return fmt.replace(/yyyy/g, yyyy)
                          .replace(/yy/g, String(yyyy).slice(-2))
                          .replace(/MM/g, mm)
                          .replace(/dd/g, dd)
                          .replace(/hh/g, hh)
                          .replace(/mm/g, min)
                          .replace(/ss/g, ss);
            }
            default: return `${yyyy}-${mm}-${dd}`;
        }
    }

    // Helper: Apply Case Transformation
    function applyCaseTransform(str) {
        switch (root.caseMode) {
            case 0: return str.toLowerCase();
            case 1: return str.toUpperCase();
            case 2: // Title Case
                return str.replace(/\w\S*/g, txt => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
            case 3: // First character uppercase
                return str.length > 0 ? (str.charAt(0).toUpperCase() + str.slice(1).toLowerCase()) : str;
            case 4: // CamelCase
                return str.replace(/[-_\s]+(.)?/g, (_, c) => c ? c.toUpperCase() : "");
            case 5: // kebab-case
                return str.replace(/([a-z])([A-Z])/g, "$1-$2").replace(/[\s_]+/g, "-").toLowerCase();
            case 6: // snake_case
                return str.replace(/([a-z])([A-Z])/g, "$1_$2").replace(/[\s-]+/g, "_").toLowerCase();
            default: return str;
        }
    }

    // Core Renaming Engine: transforms a single target segment
    function transformSegment(text, index, fileItem) {
        if (!text) return "";

        switch (root.mode) {
            case "replace": {
                if (!root.findText || root.findText.length === 0) return text;
                if (root.useRegex) {
                    try {
                        const flags = root.caseSensitive ? "g" : "gi";
                        const regex = new RegExp(root.findText, flags);
                        return text.replace(regex, root.replaceText);
                    } catch (e) {
                        return text;
                    }
                } else {
                    if (root.caseSensitive) {
                        return text.split(root.findText).join(root.replaceText);
                    } else {
                        const regex = new RegExp(root.findText.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi");
                        return text.replace(regex, root.replaceText);
                    }
                }
            }
            case "number": {
                const numStr = formatNumberString(index);
                const sep = root.numberPrefixText;
                switch (root.numberTextMode) {
                    case 0: return `${text}${sep}${numStr}`; // Name - Number
                    case 1: return `${numStr}${sep}${text}`; // Number - Name
                    case 2: { // Custom Pattern
                        const digits = (root.numberCustomPattern.match(/#+/) || ["#"])[0];
                        let paddedNum = String(root.startAt + index * Math.max(1, root.stepBy));
                        while (paddedNum.length < digits.length) paddedNum = "0" + paddedNum;
                        return root.numberCustomPattern.replace(/#+/, paddedNum).split("{name}").join(text);
                    }
                    default: return `${text}${sep}${numStr}`;
                }
            }
            case "insert": {
                const insert = root.insertText;
                const pos = Math.max(0, root.insertPosition);
                if (root.insertOffsetMode === 0) { // From Left (Start)
                    const actualPos = Math.min(pos, text.length);
                    if (root.insertAction === 0) { // Insert
                        return text.slice(0, actualPos) + insert + text.slice(actualPos);
                    } else { // Overwrite
                        return text.slice(0, actualPos) + insert + text.slice(Math.min(text.length, actualPos + insert.length));
                    }
                } else { // From Right (End)
                    const actualPos = Math.max(0, text.length - pos);
                    if (root.insertAction === 0) { // Insert
                        return text.slice(0, actualPos) + insert + text.slice(actualPos);
                    } else { // Overwrite
                        return text.slice(0, actualPos) + insert + text.slice(Math.min(text.length, actualPos + insert.length));
                    }
                }
            }
            case "remove": {
                const start = Math.max(0, root.removeStart);
                const count = Math.max(0, root.removeCount);
                if (root.removeOffsetMode === 0) { // From Left
                    const actualStart = Math.min(start, text.length);
                    const actualEnd = Math.min(text.length, actualStart + count);
                    return text.slice(0, actualStart) + text.slice(actualEnd);
                } else { // From Right
                    const actualEnd = Math.max(0, text.length - start);
                    const actualStart = Math.max(0, actualEnd - count);
                    return text.slice(0, actualStart) + text.slice(actualEnd);
                }
            }
            case "case": {
                return applyCaseTransform(text);
            }
            case "date": {
                let ts = Date.now();
                if (root.dateSource === 1) ts = fileItem.modified || ts;
                else if (root.dateSource === 2) ts = fileItem.created || ts;
                else if (root.dateSource === 3) ts = fileItem.accessed || ts;

                const dateStr = formatDateString(ts);
                const sep = root.dateSeparator;

                if (root.datePlacement === 0) { // Prefix (Start)
                    return `${dateStr}${sep}${text}`;
                } else if (root.datePlacement === 1) { // Suffix (End)
                    return `${text}${sep}${dateStr}`;
                } else { // Overwrite
                    return dateStr;
                }
            }
            default: return text;
        }
    }

    // Compute transformed target name for an item
    function computeTransformedName(item, index) {
        if (!item) return "";
        const original = item.name;
        const isDir = item.isDir;
        const dot = original.lastIndexOf(".");

        let base = (!isDir && dot > 0) ? original.substring(0, dot) : original;
        let ext = (!isDir && dot > 0) ? original.substring(dot + 1) : "";

        let newName = original;

        if (root.targetScope === 0) { // Name only
            const newBase = root.transformSegment(base, index, item);
            newName = ext.length > 0 ? `${newBase}.${ext}` : newBase;
        } else if (root.targetScope === 1) { // Extension only
            if (!isDir && ext.length > 0) {
                const newExt = root.transformSegment(ext, index, item);
                newName = `${base}.${newExt}`;
            } else {
                newName = original;
            }
        } else { // Name and extension (Full name)
            newName = root.transformSegment(original, index, item);
        }

        return newName.trim();
    }

    // Reactive list of all computed destination names
    readonly property var allTargetNames: {
        const list = root.fileItems || [];
        const names = [];
        for (let i = 0; i < list.length; i++) {
            names.push(root.computeTransformedName(list[i], i));
        }
        return names;
    }

    readonly property var nameCounts: {
        const counts = {};
        const names = root.allTargetNames || [];
        for (let i = 0; i < names.length; i++) {
            counts[names[i]] = (counts[names[i]] || 0) + 1;
        }
        return counts;
    }

    function getProblemFor(newName, index) {
        if (!newName || newName.length === 0)
            return qsTr("empty");
        if (newName.indexOf("/") >= 0)
            return qsTr("contains slash");
        if (root.nameCounts[newName] > 1)
            return qsTr("used twice");
        return "";
    }

    readonly property int changedCount: {
        let count = 0;
        const list = root.fileItems || [];
        const names = root.allTargetNames || [];
        for (let i = 0; i < list.length; i++) {
            if (names[i] !== list[i].name && root.getProblemFor(names[i], i).length === 0) {
                count++;
            }
        }
        return count;
    }

    readonly property bool hasProblem: {
        const list = root.fileItems || [];
        const names = root.allTargetNames || [];
        for (let i = 0; i < list.length; i++) {
            if (root.getProblemFor(names[i], i).length > 0) {
                return true;
            }
        }
        return false;
    }

    function moveItem(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= fileItems.length || toIdx < 0 || toIdx >= fileItems.length) return;
        const list = fileItems.slice();
        const item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        fileItems = list;
    }

    function removeItem(idx) {
        if (idx < 0 || idx >= fileItems.length) return;
        const list = fileItems.slice();
        list.splice(idx, 1);
        fileItems = list;
    }

    function sortItems(ascending) {
        const list = fileItems.slice();
        list.sort((a, b) => ascending ? a.name.localeCompare(b.name) : b.name.localeCompare(a.name));
        fileItems = list;
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    // Modal Card
    StyledRect {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 720)
        height: Math.min(parent.height - 32, 680)
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "drive_file_rename_outline"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.fileItems.length === 1
                        ? qsTr("Rename 1 item")
                        : qsTr("Bulk Rename (%1 items)").arg(root.fileItems.length)
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }

                IconButton {
                    id: sortBtn
                    type: ButtonBase.Text
                    icon: "sort_by_alpha"
                    onClicked: root.sortItems(true)

                    StyledToolTip {
                        text: qsTr("Sort A-Z")
                        visible: sortBtn.hovered
                    }
                }

                IconButton {
                    id: closeBtn
                    type: ButtonBase.Text
                    icon: "close"
                    onClicked: root.expanded = false

                    StyledToolTip {
                        text: qsTr("Close")
                        visible: closeBtn.hovered
                    }
                }
            }

            // Sliding Pill Mode Selector Track
            SlidingSelector {
                Layout.fillWidth: true

                model: [
                    { id: "replace", label: qsTr("Replace"), icon: "find_replace" },
                    { id: "number", label: qsTr("Number"), icon: "format_list_numbered" },
                    { id: "insert", label: qsTr("Insert"), icon: "edit" },
                    { id: "remove", label: qsTr("Remove"), icon: "backspace" },
                    { id: "case", label: qsTr("Case"), icon: "text_format" },
                    { id: "date", label: qsTr("Date/Time"), icon: "schedule" }
                ]
                valueKey: "id"
                currentValue: root.mode
                onSelected: value => root.mode = value
            }

            // Target Scope ("Apply to")
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    text: qsTr("Apply to:")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                ButtonGroup {
                    Layout.fillWidth: true
                    buttonHeight: 32
                    inactiveColor: Colours.palette.m3surfaceContainerHigh
                    activeColor: Colours.palette.m3primaryContainer

                    ButtonGroupItem {
                        text: qsTr("Name only")
                        checked: root.targetScope === 0
                        onClicked: root.targetScope = 0
                    }
                    ButtonGroupItem {
                        text: qsTr("Extension only")
                        checked: root.targetScope === 1
                        onClicked: root.targetScope = 1
                    }
                    ButtonGroupItem {
                        text: qsTr("Name & Extension")
                        checked: root.targetScope === 2
                        onClicked: root.targetScope = 2
                    }
                }
            }

            // Sliding Mode Parameters Box
            StyledRect {
                id: paramsBox
                Layout.fillWidth: true
                implicitHeight: {
                    let h = page0Col.implicitHeight;
                    if (root.modeIndex === 1) h = page1Col.implicitHeight;
                    else if (root.modeIndex === 2) h = page2Col.implicitHeight;
                    else if (root.modeIndex === 3) h = page3Col.implicitHeight;
                    else if (root.modeIndex === 4) h = page4Col.implicitHeight;
                    else if (root.modeIndex === 5) h = page5Col.implicitHeight;
                    return h + Tokens.padding.medium * 2;
                }
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh
                clip: true

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Row {
                    id: pagesRow
                    width: paramsBox.width * 6
                    height: paramsBox.height
                    x: -root.modeIndex * paramsBox.width

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    // 1. Search & Replace Params
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page0Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        id: findIn
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.small
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        selectByMouse: true
                                        onTextChanged: root.findText = text

                                        Text {
                                            visible: !parent.text && !parent.activeFocus
                                            text: qsTr("Find pattern / text")
                                            color: Colours.palette.m3outline
                                            font: parent.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                MaterialIcon {
                                    text: "arrow_forward"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        id: repIn
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.small
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        selectByMouse: true
                                        onTextChanged: root.replaceText = text

                                        Text {
                                            visible: !parent.text && !parent.activeFocus
                                            text: qsTr("Replace with")
                                            color: Colours.palette.m3outline
                                            font: parent.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                StyledCheckBox {
                                    text: qsTr("Case Sensitive")
                                    checked: root.caseSensitive
                                    onCheckedChanged: root.caseSensitive = checked
                                }

                                StyledCheckBox {
                                    text: qsTr("Regular Expression (Regex)")
                                    checked: root.useRegex
                                    onCheckedChanged: root.useRegex = checked
                                }
                            }
                        }
                    }

                    // 2. Numbering Params
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page1Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Format:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ButtonGroup {
                                    Layout.fillWidth: true
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: "1, 2, 3"
                                        checked: root.numberStyle === 0
                                        onClicked: root.numberStyle = 0
                                    }
                                    ButtonGroupItem {
                                        text: "01, 02"
                                        checked: root.numberStyle === 1
                                        onClicked: root.numberStyle = 1
                                    }
                                    ButtonGroupItem {
                                        text: "001, 002"
                                        checked: root.numberStyle === 2
                                        onClicked: root.numberStyle = 2
                                    }
                                    ButtonGroupItem {
                                        text: "a, b, c"
                                        checked: root.numberStyle === 4
                                        onClicked: root.numberStyle = 4
                                    }
                                    ButtonGroupItem {
                                        text: "I, II, III"
                                        checked: root.numberStyle === 7
                                        onClicked: root.numberStyle = 7
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Style:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ButtonGroup {
                                    Layout.fillWidth: true
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("Name - Number")
                                        checked: root.numberTextMode === 0
                                        onClicked: root.numberTextMode = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Number - Name")
                                        checked: root.numberTextMode === 1
                                        onClicked: root.numberTextMode = 1
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Custom Pattern")
                                        checked: root.numberTextMode === 2
                                        onClicked: root.numberTextMode = 2
                                    }
                                }

                                StyledText {
                                    text: qsTr("Start:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    implicitWidth: 50
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: String(root.startAt)
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        validator: IntValidator { bottom: 0; top: 99999 }
                                        onTextChanged: root.startAt = parseInt(text) || 1
                                    }
                                }

                                StyledText {
                                    text: qsTr("Step:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    implicitWidth: 50
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: String(root.stepBy)
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        validator: IntValidator { bottom: 1; top: 999 }
                                        onTextChanged: root.stepBy = parseInt(text) || 1
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: root.numberTextMode === 2 ? qsTr("Pattern:") : qsTr("Separator:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.small
                                        text: root.numberTextMode === 2 ? root.numberCustomPattern : root.numberPrefixText
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        onTextChanged: {
                                            if (root.numberTextMode === 2) root.numberCustomPattern = text;
                                            else root.numberPrefixText = text;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Insert / Overwrite Params
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page2Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Text:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        id: insIn
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.small
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        selectByMouse: true
                                        onTextChanged: root.insertText = text

                                        Text {
                                            visible: !parent.text && !parent.activeFocus
                                            text: qsTr("Text to insert")
                                            color: Colours.palette.m3outline
                                            font: parent.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("At position:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    implicitWidth: 50
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: String(root.insertPosition)
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        validator: IntValidator { bottom: 0; top: 999 }
                                        onTextChanged: root.insertPosition = parseInt(text) || 0
                                    }
                                }

                                ButtonGroup {
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("From Start")
                                        checked: root.insertOffsetMode === 0
                                        onClicked: root.insertOffsetMode = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("From End")
                                        checked: root.insertOffsetMode === 1
                                        onClicked: root.insertOffsetMode = 1
                                    }
                                }

                                ButtonGroup {
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("Insert")
                                        checked: root.insertAction === 0
                                        onClicked: root.insertAction = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Overwrite")
                                        checked: root.insertAction === 1
                                        onClicked: root.insertAction = 1
                                    }
                                }
                            }
                        }
                    }

                    // 4. Remove Characters Params
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page3Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Start index:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    implicitWidth: 50
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: String(root.removeStart)
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        validator: IntValidator { bottom: 0; top: 999 }
                                        onTextChanged: root.removeStart = parseInt(text) || 0
                                    }
                                }

                                StyledText {
                                    text: qsTr("Character count:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    implicitWidth: 50
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: String(root.removeCount)
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        validator: IntValidator { bottom: 0; top: 999 }
                                        onTextChanged: root.removeCount = parseInt(text) || 0
                                    }
                                }

                                ButtonGroup {
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("From Start")
                                        checked: root.removeOffsetMode === 0
                                        onClicked: root.removeOffsetMode = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("From End")
                                        checked: root.removeOffsetMode === 1
                                        onClicked: root.removeOffsetMode = 1
                                    }
                                }
                            }
                        }
                    }

                    // 5. Change Case Params (Clean 2-row layout)
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page4Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            ButtonGroup {
                                Layout.fillWidth: true
                                buttonHeight: 32
                                inactiveColor: Colours.palette.m3surfaceContainerHighest
                                activeColor: Colours.palette.m3primaryContainer

                                ButtonGroupItem {
                                    text: qsTr("lowercase")
                                    checked: root.caseMode === 0
                                    onClicked: root.caseMode = 0
                                }
                                ButtonGroupItem {
                                    text: qsTr("UPPERCASE")
                                    checked: root.caseMode === 1
                                    onClicked: root.caseMode = 1
                                }
                                ButtonGroupItem {
                                    text: qsTr("Title Case")
                                    checked: root.caseMode === 2
                                    onClicked: root.caseMode = 2
                                }
                            }

                            ButtonGroup {
                                Layout.fillWidth: true
                                buttonHeight: 32
                                inactiveColor: Colours.palette.m3surfaceContainerHighest
                                activeColor: Colours.palette.m3primaryContainer

                                ButtonGroupItem {
                                    text: qsTr("First upper")
                                    checked: root.caseMode === 3
                                    onClicked: root.caseMode = 3
                                }
                                ButtonGroupItem {
                                    text: qsTr("kebab-case")
                                    checked: root.caseMode === 5
                                    onClicked: root.caseMode = 5
                                }
                                ButtonGroupItem {
                                    text: qsTr("snake_case")
                                    checked: root.caseMode === 6
                                    onClicked: root.caseMode = 6
                                }
                            }
                        }
                    }

                    // 6. Insert Date / Time Params
                    Item {
                        width: paramsBox.width
                        height: paramsBox.height

                        ColumnLayout {
                            id: page5Col
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Source:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ButtonGroup {
                                    Layout.fillWidth: true
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("Current Date")
                                        checked: root.dateSource === 0
                                        onClicked: root.dateSource = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Modified")
                                        checked: root.dateSource === 1
                                        onClicked: root.dateSource = 1
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Created")
                                        checked: root.dateSource === 2
                                        onClicked: root.dateSource = 2
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Format:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ButtonGroup {
                                    Layout.fillWidth: true
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: "YYYY-MM-DD"
                                        checked: root.dateFormat === 0
                                        onClicked: root.dateFormat = 0
                                    }
                                    ButtonGroupItem {
                                        text: "YYYYMMDD"
                                        checked: root.dateFormat === 1
                                        onClicked: root.dateFormat = 1
                                    }
                                    ButtonGroupItem {
                                        text: "YYYY-MM-DD_HH-MM"
                                        checked: root.dateFormat === 2
                                        onClicked: root.dateFormat = 2
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Placement:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ButtonGroup {
                                    Layout.fillWidth: true
                                    buttonHeight: 32
                                    inactiveColor: Colours.palette.m3surfaceContainerHighest
                                    activeColor: Colours.palette.m3primaryContainer

                                    ButtonGroupItem {
                                        text: qsTr("Prefix (Start)")
                                        checked: root.datePlacement === 0
                                        onClicked: root.datePlacement = 0
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Suffix (End)")
                                        checked: root.datePlacement === 1
                                        onClicked: root.datePlacement = 1
                                    }
                                    ButtonGroupItem {
                                        text: qsTr("Overwrite")
                                        checked: root.datePlacement === 2
                                        onClicked: root.datePlacement = 2
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: qsTr("Separator:")
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: Tokens.rounding.small
                                    color: Colours.palette.m3surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        text: root.dateSeparator
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        onTextChanged: root.dateSeparator = text
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Preview List Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item { implicitWidth: 44 }

                StyledText {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("Original Name")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item { implicitWidth: 24 }

                StyledText {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("New Name")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item { implicitWidth: 24 }
            }

            // Preview List
            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerLow
                clip: true

                ListView {
                    id: previewList
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    model: root.fileItems
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 4

                    ScrollBar.vertical: StyledScrollBar {
                        flickable: previewList
                    }

                    delegate: StyledRect {
                        id: rowRect
                        required property int index
                        required property var modelData

                        readonly property string fromName: modelData ? modelData.name : ""
                        readonly property string toName: (root.allTargetNames && index < root.allTargetNames.length) ? root.allTargetNames[index] : fromName
                        readonly property bool isChanged: toName !== fromName
                        readonly property string problemText: root.getProblemFor(toName, index)

                        width: previewList.width
                        implicitHeight: 40
                        radius: Tokens.rounding.medium
                        color: rowRect.problemText.length > 0
                            ? Qt.alpha(Colours.palette.m3errorContainer, 0.4)
                            : (rowRect.isChanged
                                ? Qt.alpha(Colours.palette.m3primaryContainer, rowHover.containsMouse ? 0.4 : 0.25)
                                : (rowHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh))

                        Behavior on color {
                            ColorAnimation {
                                duration: Tokens.anim.durations.expressiveFastEffects
                                easing: Tokens.anim.expressiveFastEffects
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.small
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            // Move Controls (Always interactive, brighter on hover)
                            RowLayout {
                                implicitWidth: 44
                                spacing: 0

                                MaterialIcon {
                                    text: "arrow_upward"
                                    color: rowRect.index > 0 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                    opacity: rowHover.containsMouse ? 1.0 : 0.45
                                    Behavior on opacity { Anim { type: Anim.FastEffects } }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: rowRect.index > 0 ? Qt.PointingHandCursor : undefined
                                        onClicked: root.moveItem(rowRect.index, rowRect.index - 1)
                                    }
                                }

                                MaterialIcon {
                                    text: "arrow_downward"
                                    color: rowRect.index < root.fileItems.length - 1 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                    opacity: rowHover.containsMouse ? 1.0 : 0.45
                                    Behavior on opacity { Anim { type: Anim.FastEffects } }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: rowRect.index < root.fileItems.length - 1 ? Qt.PointingHandCursor : undefined
                                        onClicked: root.moveItem(rowRect.index, rowRect.index + 1)
                                    }
                                }
                            }

                            // Original Name Container Pill
                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 28
                                radius: Tokens.rounding.small
                                color: Colours.palette.m3surfaceContainer

                                StyledText {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.small
                                    anchors.rightMargin: Tokens.padding.small
                                    verticalAlignment: Text.AlignVCenter
                                    text: rowRect.fromName
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                    elide: Text.ElideMiddle
                                }
                            }

                            MaterialIcon {
                                text: "arrow_forward"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.small
                            }

                            // New Name Container Pill (with animated color fade)
                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 28
                                radius: Tokens.rounding.small
                                color: rowRect.problemText.length > 0
                                    ? Colours.palette.m3errorContainer
                                    : (rowRect.isChanged ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Tokens.anim.durations.expressiveFastEffects
                                        easing: Tokens.anim.expressiveFastEffects
                                    }
                                }

                                StyledText {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.small
                                    anchors.rightMargin: Tokens.padding.small
                                    verticalAlignment: Text.AlignVCenter
                                    animate: true
                                    text: rowRect.problemText.length > 0
                                        ? qsTr("%1 (%2)").arg(rowRect.toName).arg(rowRect.problemText)
                                        : rowRect.toName
                                    color: rowRect.problemText.length > 0
                                        ? Colours.palette.m3onErrorContainer
                                        : (rowRect.isChanged ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant)
                                    font: rowRect.isChanged ? Tokens.font.body.builders.small.weight(Font.Bold).build() : Tokens.font.body.small
                                    elide: Text.ElideMiddle

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Tokens.anim.durations.expressiveFastEffects
                                            easing: Tokens.anim.expressiveFastEffects
                                        }
                                    }
                                }
                            }

                            // Remove item button
                            MaterialIcon {
                                text: "close"
                                color: removeHover.containsMouse ? Colours.palette.m3error : Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.small
                                opacity: rowHover.containsMouse ? 1.0 : 0.4
                                Behavior on opacity { Anim { type: Anim.FastEffects } }

                                MouseArea {
                                    id: removeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeItem(rowRect.index)
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.hasProblem
                        ? qsTr("Resolve the highlighted conflicts to continue")
                        : (root.changedCount === 1
                            ? qsTr("1 name will change")
                            : qsTr("%1 names will change").arg(root.changedCount))
                    color: root.hasProblem ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.expanded = false
                }

                StyledRect {
                    implicitWidth: 100
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    opacity: (!root.hasProblem && root.changedCount > 0) ? 1.0 : 0.4
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        onClicked: {
                            if (root.hasProblem || root.changedCount === 0)
                                return;
                            root.applied(root.fileItems.map(item => item.path), root.allTargetNames);
                            root.expanded = false;
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Rename")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
