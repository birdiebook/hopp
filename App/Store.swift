import Foundation
import Observation
import Jump

/// Historiken och videorna. Allt ligger i appens Application Support och
/// lämnar aldrig telefonen (CLAUDE.md, Dataregeln).
@Observable
final class Store {
    private(set) var history = History()
    /// Visas på startsidan när filen inte gick att läsa eller skriva.
    var problem: String?

    static let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "Airtime", directoryHint: .isDirectory)
    }()
    static var videos: URL { folder.appending(path: "Videor", directoryHint: .isDirectory) }
    private static var file: URL { folder.appending(path: "historik.json") }

    init() {
        var dir = Self.videos
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Videorna är stora och går att spela in igen: de ska inte ta plats i iCloud-backupen.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.file) else { return }
        do {
            history = try History.decode(data)
        } catch {
            // En fil som inte går att läsa skrivs aldrig över: den flyttas undan och finns kvar.
            let aside = Self.folder.appending(path: "historik-oläslig-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: Self.file, to: aside)
            problem = "Historiken gick inte att läsa. Den gamla filen är sparad som \(aside.lastPathComponent)."
        }
    }

    private func save() {
        do {
            try history.encoded().write(to: Self.file, options: .atomic)
        } catch {
            problem = "Historiken gick inte att spara."
        }
    }

    var days: [JumpDay] { Analysis.days(history.attempts, calendar: .current) }

    func setBodyMass(_ kg: Double) {
        history.bodyMassKg = kg
        save()
    }

    func setBodyHeight(_ cm: Double) {
        history.bodyHeightCm = cm
        save()
    }

    func setPlaysRightHanded(_ right: Bool) {
        history.playsRightHanded = right
        save()
    }

    func add(_ attempt: JumpAttempt) {
        history.attempts.append(attempt)
        save()
    }

    func delete(_ attempt: JumpAttempt) {
        history.attempts.removeAll { $0.id == attempt.id }
        save()
        if let name = attempt.videoFileName { deleteVideoIfUnused(Self.videos.appending(path: name)) }
    }

    /// Tar bort en video som inget sparat hopp pekar på. Rör aldrig en fil utanför appens videomapp.
    func deleteVideoIfUnused(_ url: URL) {
        guard url.deletingLastPathComponent().standardizedFileURL == Self.videos.standardizedFileURL else { return }
        let name = url.lastPathComponent
        guard !history.attempts.contains(where: { $0.videoFileName == name }) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
