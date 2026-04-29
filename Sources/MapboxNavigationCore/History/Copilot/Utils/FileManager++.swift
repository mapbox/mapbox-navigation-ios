import Foundation

extension FileManager {
    static let applicationSupportURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!

    func removeFiles(in directory: URL, createdBefore deadline: Date) {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.addedToDirectoryDateKey]
        ) else { return }

        enumerator
            .compactMap { (element: NSEnumerator.Element) -> (url: URL, date: Date)? in
                guard let url = element as? URL,
                      let resourceValues = try? url.resourceValues(forKeys: [.addedToDirectoryDateKey]),
                      let date = resourceValues.addedToDirectoryDate
                else { return nil }
                return (url: url, date: date)
            }
            .filter { $0.date < deadline }
            .forEach {
                try? FileManager.default.removeItem(atPath: $0.url.path)
            }
    }
}
