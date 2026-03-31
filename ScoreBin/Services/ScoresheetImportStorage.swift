import Foundation
import UIKit

final class ScoresheetImportStorage {
    static let shared = ScoresheetImportStorage()

    private let fileManager = FileManager.default
    private let rootFolderName = "ImportedScoresheets"

    private init() {}

    func storeSourceData(_ data: Data, fileName: String, draftID: UUID) throws -> String {
        let directory = try directoryURL(for: draftID)
        let sanitizedName = sanitizedFileName(fileName)
        let targetURL = directory.appendingPathComponent(sanitizedName)
        try data.write(to: targetURL, options: .atomic)
        return relativePath(for: targetURL)
    }

    func storeSourceFile(at url: URL, fileName: String? = nil, draftID: UUID) throws -> String {
        let directory = try directoryURL(for: draftID)
        let targetName = sanitizedFileName(fileName ?? url.lastPathComponent)
        let targetURL = directory.appendingPathComponent(targetName)
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.copyItem(at: url, to: targetURL)
        return relativePath(for: targetURL)
    }

    func storePreviewImage(_ image: UIImage, draftID: UUID) throws -> String {
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw ScoresheetImportError.storageFailure
        }
        let directory = try directoryURL(for: draftID)
        let targetURL = directory.appendingPathComponent("preview.jpg")
        try jpegData.write(to: targetURL, options: .atomic)
        return relativePath(for: targetURL)
    }

    func url(forRelativePath relativePath: String?) -> URL? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let rootURL = applicationSupportRootURL()
        return rootURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    func image(forRelativePath relativePath: String?) -> UIImage? {
        guard let url = url(forRelativePath: relativePath) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func directoryURL(for draftID: UUID) throws -> URL {
        let rootURL = applicationSupportRootURL()
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let directory = rootURL.appendingPathComponent(draftID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func applicationSupportRootURL() -> URL {
        let baseURL =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent(rootFolderName, isDirectory: true)
    }

    private func sanitizedFileName(_ fileName: String) -> String {
        let fallback = "imported-source"
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }

        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = trimmed.components(separatedBy: invalidCharacters).joined(separator: "-")
        return cleaned.isEmpty ? fallback : cleaned
    }

    private func relativePath(for url: URL) -> String {
        let rootURL = applicationSupportRootURL()
        let rootPath = rootURL.standardizedFileURL.path
        let targetPath = url.standardizedFileURL.path
        guard targetPath.hasPrefix(rootPath) else {
            return url.lastPathComponent
        }
        let relative = String(targetPath.dropFirst(rootPath.count)).trimmingCharacters(
            in: CharacterSet(charactersIn: "/"))
        return relative
    }
}
