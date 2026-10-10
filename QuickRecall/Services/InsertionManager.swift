import Cocoa
import ApplicationServices

enum InsertionManager {

    /// Time to let the target app settle before synthesising ⌘V.
    private static let pasteDelay: TimeInterval = 0.15
    /// Time to let the target app consume the paste before we restore the clipboard.
    private static let restoreDelay: TimeInterval = 0.6

    static func performKeystrokePaste() -> Bool {
        guard AXIsProcessTrusted() else { return false }
        let vKeyCode: CGKeyCode = 9 // "v"

        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            Log.insertion.error("Failed to create keyboard events for paste")
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        return true
    }

    static func insert(
        text: String,
        copyOnly: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) {
        let pasteboard = NSPasteboard.general
        let previous = snapshot(of: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let changeCountAfterWrite = pasteboard.changeCount

        guard !copyOnly else {
            completion?(true)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pasteDelay) {
            let success = performKeystrokePaste()

            guard success else {
                // Leave the snippet on the clipboard so the user can paste manually.
                Log.insertion.notice("Paste failed; leaving snippet on clipboard as a fallback")
                completion?(false)
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                restore(previous, to: pasteboard, ifChangeCountIs: changeCountAfterWrite)
                completion?(true)
            }
        }
    }

    /// Copies every representation of the current clipboard contents, not just plain text,
    /// so images, files and rich text survive a snippet insertion.
    private static func snapshot(of pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    /// Restores a snapshot only if nothing else has written to the clipboard in the meantime,
    /// so we never clobber something the user copied while the paste was in flight.
    private static func restore(
        _ items: [NSPasteboardItem],
        to pasteboard: NSPasteboard,
        ifChangeCountIs expected: Int
    ) {
        guard pasteboard.changeCount == expected else {
            Log.insertion.debug("Clipboard changed during insertion; skipping restore")
            return
        }

        pasteboard.clearContents()
        guard !items.isEmpty else { return }
        pasteboard.writeObjects(items)
    }
}
