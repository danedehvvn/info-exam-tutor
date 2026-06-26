import SwiftUI
import PhotosUI
import Combine

@MainActor
final class SolveViewModel: ObservableObject {
    @Published var questionText: String = ""
    @Published var kind: ProblemKind = .auto
    @Published var pickedImages: [UIImage] = []

    @Published var answer: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var hasInput: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pickedImages.isEmpty
    }

    /// PhotosPicker 선택 항목을 UIImage로 변환해 저장한다.
    func loadImages(from items: [PhotosPickerItem]) async {
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        pickedImages = loaded
    }

    func removeImage(at index: Int) {
        guard pickedImages.indices.contains(index) else { return }
        pickedImages.remove(at: index)
    }

    func solve(settings: AppSettings, history: HistoryStore) {
        guard !isLoading else { return }
        answer = ""
        errorMessage = nil
        isLoading = true

        let imageData = pickedImages.compactMap { $0.downscaledJPEG() }
        let client = ClaudeClient(apiKey: settings.apiKey, model: settings.model.rawValue)
        let text = questionText
        let hint = kind.hint
        let hadImages = !imageData.isEmpty

        Task {
            do {
                try await client.solve(questionText: text, images: imageData, kindHint: hint) { delta in
                    self.answer += delta
                }
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            self.isLoading = false

            // 성공적으로 답을 받았으면 기록에 저장한다.
            if self.errorMessage == nil, !self.answer.isEmpty {
                let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let title = q.isEmpty ? (hadImages ? "📷 이미지 문제" : "문제") : q
                history.add(SolvedRecord(kind: self.kind.rawValue, question: title, answer: self.answer))
            }
        }
    }
}
