pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    property string wallpaper: ""
    property bool blur: true
    property int cornerRadius: 10
    property string fontFamily: "JetBrainsMono Nerd Font"
    property string pamConfig: "quickshell-lock"
    property int autoUnlock: 0

    property string buffer: ""
    property int failure: 0

    readonly property bool checking: pam.active

    signal rejected

    function handleKey(event: KeyEvent): void {
        if (pam.active || failure === 3)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            pam.start();
        } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_U) && (event.modifiers & Qt.ControlModifier)) {
            buffer = "";
        } else if (event.key === Qt.Key_Backspace) {
            buffer = buffer.slice(0, -1);
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
        }
    }

    WlSessionLock {
        id: session

        LockSurface {
            controller: root
        }

        onSecureChanged: {
            if (secure) {
                root.buffer = "";
                root.failure = 0;
            }
        }
    }

    PamContext {
        id: pam

        config: root.pamConfig

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                session.locked = false;
                return;
            }

            if (result === PamResult.Error)
                root.failure = 2;
            else if (result === PamResult.MaxTries)
                root.failure = 3;
            else
                root.failure = 1;

            root.rejected();
            failureReset.restart();
        }
    }

    Timer {
        id: failureReset

        interval: 4000
        onTriggered: {
            if (root.failure !== 3)
                root.failure = 0;
        }
    }

    Timer {
        interval: root.autoUnlock * 1000
        running: root.autoUnlock > 0 && session.locked
        onTriggered: session.locked = false
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            session.locked = true;
        }

        function unlock(): void {
            session.locked = false;
        }

        function isLocked(): bool {
            return session.locked;
        }
    }
}
