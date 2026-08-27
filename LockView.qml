import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property string liveVideoPath: ""
  property int liveVideoVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property date now: new Date()

  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "User"
  readonly property string greeting: now.getHours() < 12 ? "Good morning" : (now.getHours() < 18 ? "Good afternoon" : "Good evening")
  readonly property real panelWidth: Math.max(330, Math.min(440, width * 0.31))
  readonly property int fieldHeight: 58
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.05)
  readonly property bool errorState: failureMessage.length > 0
  readonly property bool showCursor: inputEnabled && !authenticatingPassword && !errorState
  readonly property bool hasLiveVideo: loadBackground && liveVideoPath.length > 0
  readonly property bool liveVideoPlaying: wallpaperPlayer.playbackState === MediaPlayer.PlayingState

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function mediaUrl(path) {
    if (!path) return ""
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  function forcePasswordFocus() { passwordInput.forceActiveFocus() }
  function syncPassword() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPassword()
  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
  Component.onCompleted: {
    syncPassword()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      visible: !root.hasLiveVideo
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MediaPlayer {
      id: wallpaperPlayer
      source: root.hasLiveVideo ? root.mediaUrl(root.liveVideoPath) : ""
      videoOutput: videoWallpaper
      loops: MediaPlayer.Infinite
      autoPlay: root.hasLiveVideo
    }

    VideoOutput {
      id: videoWallpaper
      anchors.fill: parent
      visible: root.hasLiveVideo
      fillMode: VideoOutput.PreserveAspectCrop
    }

    // A restrained wash preserves the wallpaper rather than turning it into a blur.
    Rectangle {
      anchors.fill: parent
      color: "#071008"
      opacity: root.hasLiveVideo || wallpaper.status === Image.Ready ? 0.18 : 0
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: Math.max(36, parent.width * 0.04)
      anchors.bottomMargin: Math.max(34, parent.height * 0.06)
      spacing: 3

      Text {
        text: Qt.formatTime(root.now, "HH:mm")
        color: "#F1E8D4"
        font.family: Style.font.family
        font.pixelSize: Math.max(60, Math.round(parent.parent.height * 0.115))
        font.weight: Font.DemiBold
        font.letterSpacing: -2
      }
      Text {
        text: Qt.formatDate(root.now, "dddd, d MMMM")
        color: Qt.rgba(0.94, 0.91, 0.82, 0.78)
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.subtitle * 1.2)
        font.letterSpacing: 1.2
      }
    }

    Rectangle {
      id: panel
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: root.panelWidth
      color: "transparent"

      // Re-render the matching part of the wallpaper here, then blur it. This
      // creates a frosted-glass surface instead of a dark opaque sidebar.
      Item {
        anchors.fill: parent
        clip: true

        Image {
          id: panelWallpaper
          x: -panel.x
          y: -panel.y
          width: root.width
          height: root.height
          source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          visible: false
          sourceSize.width: width
          sourceSize.height: height
        }

        MultiEffect {
          x: -panel.x
          y: -panel.y
          width: root.width
          height: root.height
          source: root.hasLiveVideo ? videoWallpaper : panelWallpaper
          autoPaddingEnabled: false
          blurEnabled: root.loadBackground && (root.hasLiveVideo || panelWallpaper.status === Image.Ready)
          blur: 0.72
          blurMax: 96
          blurMultiplier: 1.15
          contrast: -0.05
          brightness: -0.08
        }
      }

      // Neutral highlight and shade: readable contents without tinting the glass.
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.07)
      }
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.10)
      }

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Qt.rgba(1, 1, 1, 0.16)
      }

      Column {
        width: parent.width - 72
        anchors.centerIn: parent
        spacing: 16

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 54
          height: width
          radius: width / 2
          color: "#E8E8E8"
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.36)

          Rectangle {
            id: avatarMask
            anchors.fill: parent
            radius: width / 2
            color: "white"
            visible: false
            layer.enabled: true
          }

          Image {
            id: avatarImage
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.face"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: parent.width * 2
            sourceSize.height: parent.height * 2
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: avatarMask
              maskThresholdMin: 0.3
              maskSpreadAtMin: 0.3
            }
          }
          Text {
            anchors.centerIn: parent
            text: root.userName.charAt(0).toUpperCase()
            visible: avatarImage.status !== Image.Ready
            color: "#303030"
            font.family: Style.font.family
            font.pixelSize: 22
            font.weight: Font.DemiBold
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.greeting
          color: Qt.rgba(0.94, 0.91, 0.82, 0.66)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.8
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.userName.toUpperCase()
          color: "#F1E8D4"
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.weight: Font.Medium
        }

        Item { width: 1; height: 10 }

        Rectangle {
          id: inputFrame
          width: parent.width
          height: root.fieldHeight
          radius: 8
          color: Qt.rgba(0.03, 0.08, 0.04, 0.54)
          border.width: root.errorState ? 2 : 1
          border.color: root.errorState ? Color.lock.textError : (passwordInput.activeFocus ? "#F1F1F1" : Qt.rgba(1, 1, 1, 0.40))

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: root.fingerprintConfigured ? 48 : 18
            verticalAlignment: TextInput.AlignVCenter
            activeFocusOnPress: true
            enabled: root.inputEnabled && !root.authenticatingPassword
            readOnly: root.authenticatingPassword
            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: "#F1E8D4"
            selectionColor: Color.lock.selection
            selectedTextColor: "#071208"
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
            cursorVisible: activeFocus && root.showCursor && text.length > 0

            onTextChanged: {
              if (!root.syncingPasswordText) root.passwordTextEdited(text)
              if (text.length > 0) root.wakeRequested()
              if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
            }
            onAccepted: {
              var submitted = root.passwordText
              root.passwordTextEdited("")
              if (submitted.length > 0) root.submitPassword(submitted)
            }
            Keys.onPressed: function(event) {
              root.wakeRequested()
              if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                root.passwordTextEdited("")
                event.accepted = true
              }
            }
          }

          Text {
            anchors.fill: passwordInput
            text: root.authenticatingPassword ? "Checking…" : (root.errorState ? root.failureMessage : "Enter password")
            visible: passwordInput.text.length === 0
            color: root.authenticatingPassword ? "#F1E8D4" : (root.errorState ? Color.lock.textError : Qt.rgba(0.94, 0.91, 0.82, 0.55))
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
            verticalAlignment: Text.AlignVCenter
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: 17
            anchors.verticalCenter: parent.verticalCenter
            visible: root.fingerprintConfigured
            text: "󰈷"
            color: Qt.rgba(1, 1, 1, 0.68)
            font.family: Style.font.family
            font.pixelSize: 20
          }
        }

        Text {
          width: parent.width
          visible: root.fingerprintConfigured
          text: "Fingerprint available"
          horizontalAlignment: Text.AlignHCenter
          color: Qt.rgba(1, 1, 1, 0.56)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Item { width: 1; height: 12 }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Session secured"
          color: Qt.rgba(0.94, 0.91, 0.82, 0.32)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.2
        }
      }
    }
  }
}
