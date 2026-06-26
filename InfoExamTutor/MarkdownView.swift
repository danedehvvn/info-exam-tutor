import SwiftUI

/// 가벼운 마크다운 렌더러. 헤더/코드블록/표/불릿/문단을 처리한다.
/// (외부 라이브러리 없이 정보처리기사 풀이 답안을 보기 좋게 표시하는 용도)
struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                block.view
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [Block] {
        Block.parse(text)
    }
}

private struct Block: Identifiable {
    let id = UUID()
    let view: AnyView

    static func parse(_ text: String) -> [Block] {
        var result: [Block] = []
        let lines = text.components(separatedBy: "\n")

        var i = 0
        var tableBuffer: [String] = []

        func flushTable() {
            guard !tableBuffer.isEmpty else { return }
            result.append(Block(view: AnyView(TableView(rows: tableBuffer))))
            tableBuffer.removeAll()
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 코드 블록 ```
            if trimmed.hasPrefix("```") {
                flushTable()
                var code: [String] = []
                i += 1
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1 // 닫는 ``` 건너뛰기
                result.append(Block(view: AnyView(CodeBlock(code: code.joined(separator: "\n")))))
                continue
            }

            // 표 (| ... |)
            if trimmed.hasPrefix("|"), trimmed.hasSuffix("|") {
                tableBuffer.append(trimmed)
                i += 1
                continue
            } else {
                flushTable()
            }

            // 헤더
            if trimmed.hasPrefix("### ") {
                result.append(Block(view: AnyView(
                    Text(Block.inline(String(trimmed.dropFirst(4))))
                        .font(.headline)
                        .padding(.top, 2)
                )))
            } else if trimmed.hasPrefix("## ") {
                result.append(Block(view: AnyView(
                    Text(Block.inline(String(trimmed.dropFirst(3))))
                        .font(.title3.bold())
                        .padding(.top, 4)
                )))
            } else if trimmed.hasPrefix("# ") {
                result.append(Block(view: AnyView(
                    Text(Block.inline(String(trimmed.dropFirst(2))))
                        .font(.title2.bold())
                        .padding(.top, 4)
                )))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                result.append(Block(view: AnyView(
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").bold()
                        Text(Block.inline(String(trimmed.dropFirst(2))))
                    }
                )))
            } else if trimmed.isEmpty {
                // 빈 줄 — 간격만 (별도 뷰 불필요)
            } else {
                result.append(Block(view: AnyView(
                    Text(Block.inline(trimmed)).fixedSize(horizontal: false, vertical: true)
                )))
            }
            i += 1
        }
        flushTable()
        return result
    }

    /// 인라인 마크다운(**굵게**, `코드`, *기울임*)을 AttributedString으로.
    static func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}

private struct CodeBlock: View {
    let code: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .padding(12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TableView: View {
    let rows: [String]

    private var parsed: [[String]] {
        rows.compactMap { row -> [String]? in
            var c = row.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            // 양끝 빈 셀 제거
            if c.first == "" { c.removeFirst() }
            if c.last == "" { c.removeLast() }
            // 구분선(---) 행은 제외
            if c.allSatisfy({ $0.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").isEmpty }) {
                return nil
            }
            return c
        }
    }

    var body: some View {
        let table = parsed
        VStack(spacing: 0) {
            ForEach(Array(table.enumerated()), id: \.offset) { rowIndex, cells in
                HStack(spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                        Text(Block.inline(cell))
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
                .background(rowIndex == 0 ? Color(.tertiarySystemBackground) : Color.clear)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
