import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var history: HistoryStore

    var body: some View {
        NavigationStack {
            Group {
                if history.records.isEmpty {
                    ContentUnavailableView(
                        "아직 푼 문제가 없어요",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("문제를 풀면 여기에 자동으로 기록됩니다.")
                    )
                } else {
                    List {
                        ForEach(history.records) { record in
                            NavigationLink {
                                HistoryDetailView(record: record)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.question)
                                        .lineLimit(2)
                                    HStack {
                                        Text(record.kind)
                                        Spacer()
                                        Text(record.date, format: .dateTime.month().day().hour().minute())
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete { history.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("기록")
            .toolbar {
                if !history.records.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

struct HistoryDetailView: View {
    let record: SolvedRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(record.question)
                    .font(.headline)
                Divider()
                MarkdownView(text: record.answer)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle("풀이")
        .navigationBarTitleDisplayMode(.inline)
    }
}
