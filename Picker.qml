import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

// Summoned by `browser-picker` with {"command": "...", "url": "...", "options": [{id, label, key, icon, glyph}]}.
// An icon that is missing or fails to load falls back to the glyph.
// Choosing runs `browser-picker --open <id> [url]`; the picker knows nothing about browsers.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // The script sends its own path; a bare name falls back to PATH.
  property string command: "browser-picker"
  property bool opened: false
  property string url: ""
  property var options: []
  property int selectedIndex: 0
  property string lastChoice: ""

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int padding: Style.spacing.panelPadding
  property int rowHeight: Math.max(Style.space(44), Style.font.heading + Style.spacing.lg * 2)

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) {}
    root.url = String(payload.url || "")
    root.options = Array.isArray(payload.options) ? payload.options : []
    root.command = String(payload.command || "browser-picker")
    // Start on the last profile chosen in this session.
    root.selectedIndex = Math.max(0, root.options.findIndex(function(o) { return o.id === root.lastChoice }))
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "kierangraham.browser-picker")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function move(delta) {
    if (root.options.length) root.selectedIndex = (root.selectedIndex + delta + root.options.length) % root.options.length
  }

  function choose(index) {
    var option = root.options[index]
    if (!option) return
    root.lastChoice = option.id
    var args = [root.command, "--open", option.id]
    if (root.url) args.push(root.url)
    root.dismiss()
    Quickshell.execDetached(args)
  }

  // "https://github.com/foo/bar?x" → "github.com/foo/bar?x"
  function displayUrl(value) {
    return value.replace(/^https?:\/\//, "").replace(/\/$/, "")
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-browser-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(380), panel.width - Style.gapsOut * 2)
      height: content.implicitHeight + card.contentTopInset + card.contentBottomInset
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.padding

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          var key = event.key
          if (key === Qt.Key_Escape) {
            root.dismiss()
          } else if (key === Qt.Key_Down || key === Qt.Key_Tab || (key === Qt.Key_J && !event.modifiers)) {
            root.move(1)
          } else if (key === Qt.Key_Up || key === Qt.Key_Backtab || (key === Qt.Key_K && !event.modifiers)) {
            root.move(-1)
          } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            root.choose(root.selectedIndex)
          } else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
            root.choose(key - Qt.Key_1)
          } else {
            var typed = (event.text || "").toLowerCase()
            var index = root.options.findIndex(function(o) { return o.key && o.key === typed })
            if (index < 0) return
            root.choose(index)
          }
          event.accepted = true
        }
      }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: card.contentTopInset
        anchors.leftMargin: card.contentLeftInset
        anchors.rightMargin: card.contentRightInset
        spacing: Style.spacing.md

        Column {
          width: parent.width
          spacing: Style.spacing.xs
          bottomPadding: Style.spacing.sm

          Text {
            textFormat: Text.PlainText
            text: root.url ? "Open link in" : "New window in"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: root.url !== ""
            text: root.displayUrl(root.url)
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideMiddle
          }
        }

        Repeater {
          model: root.options

          delegate: Rectangle {
            required property int index
            required property var modelData

            readonly property bool current: index === root.selectedIndex

            width: content.width
            height: root.rowHeight
            radius: root.cornerRadius
            color: current ? root.selectedBackground : "transparent"

            Row {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.xxl

              Item {
                width: Style.space(24)
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Image {
                  id: iconImage
                  anchors.fill: parent
                  visible: !!modelData.icon && status !== Image.Error
                  source: modelData.icon ? "file://" + modelData.icon : ""
                  sourceSize.width: width * 2
                  sourceSize.height: height * 2
                  smooth: true
                }

                Text {
                  anchors.centerIn: parent
                  visible: !iconImage.visible
                  text: modelData.glyph || ""
                  color: current ? root.selectedText : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.space(22)
                }
              }

              Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: current ? root.selectedText : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.heading
              }
            }

            Rectangle {
              visible: !!modelData.key
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(height, keyText.implicitWidth + Style.spacing.lg)
              height: keyText.implicitHeight + Style.spacing.xs * 2
              radius: Math.min(root.cornerRadius, height / 2)
              color: "transparent"
              border.width: 1
              border.color: Qt.alpha(root.foreground, 0.25)

              Text {
                id: keyText
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: (modelData.key || "").toUpperCase()
                color: root.foreground
                opacity: 0.7
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: if (containsMouse) root.selectedIndex = index
              onClicked: root.choose(index)
            }
          }
        }
      }
    }
  }
}
