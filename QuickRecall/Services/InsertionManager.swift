import Cocoa
import ApplicationServices

enum InsertionManager {

    static func performKeystrokePaste() -> Bool {
        guard AXIsProcessTrusted() else { return false }
        let vKeyCode: CGKeyCode = 9 // "v"
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Disable local keyboard events to prevent conflicts (optional, but good practice)
        // source?.localEventsFilterDuringSuppressionState = [.permitLocalMouseEvents, .permitGlobalMouseEvents, .permitLocalKeyboardEvents, .permitGlobalKeyboardEvents]

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
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
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard !copyOnly else {
            completion?(true)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let success = performKeystrokePaste()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let prev = previous {
                    pasteboard.clearContents()
                    pasteboard.setString(prev, forType: .string)
                }
                completion?(success)
            }
        }
    }
}
