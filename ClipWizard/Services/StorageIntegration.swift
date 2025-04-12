import Foundation
import AppKit

// We don't need the AppDelegate extension - this should be incorporated directly
// into the AppDelegate class since it accesses private properties

// Add a notification name for showing the storage tab
extension NSNotification.Name {
    static let showStorageTab = NSNotification.Name("showStorageTab")
}
