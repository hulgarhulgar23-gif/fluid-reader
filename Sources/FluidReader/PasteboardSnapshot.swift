import AppKit

struct PasteboardSnapshot {
    let items: [PasteboardItemSnapshot]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { item in
            PasteboardItemSnapshot(
                values: item.types.compactMap { type in
                    guard let data = item.data(forType: type) else { return nil }
                    return (type, data)
                }
            )
        } ?? []
        return PasteboardSnapshot(items: items)
    }

    /// Restores the snapshot. When `expectedChangeCount` is provided, the
    /// restore is skipped if another writer has since modified the pasteboard,
    /// so the user's newer clipboard content is not clobbered.
    @discardableResult
    func restore(to pasteboard: NSPasteboard, ifChangeCountEquals expectedChangeCount: Int? = nil) -> Bool {
        if let expectedChangeCount, pasteboard.changeCount != expectedChangeCount {
            return false
        }
        pasteboard.clearContents()
        let restoredItems = items.map { snapshot in
            let item = NSPasteboardItem()
            snapshot.values.forEach { type, data in
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(restoredItems)
        return true
    }
}

struct PasteboardItemSnapshot {
    let values: [(NSPasteboard.PasteboardType, Data)]
}
