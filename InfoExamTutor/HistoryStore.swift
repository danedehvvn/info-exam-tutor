import Foundation
import Combine

/// 푼 문제 기록을 기기 내 JSON 파일에 저장/불러온다.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [SolvedRecord] = []

    private let url: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("history.json")
    }()

    init() {
        load()
    }

    func add(_ record: SolvedRecord) {
        records.insert(record, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where records.indices.contains(index) {
            records.remove(at: index)
        }
        save()
    }

    func clearAll() {
        records.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SolvedRecord].self, from: data) else { return }
        records = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
