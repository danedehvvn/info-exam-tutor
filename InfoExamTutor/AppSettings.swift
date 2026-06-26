import Foundation
import Combine

/// 앱 전역 설정. API 키는 키체인에, 모델 선택은 UserDefaults에 저장한다.
@MainActor
final class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { Keychain.save(apiKey) }
    }

    @Published var model: ClaudeModel {
        didSet { UserDefaults.standard.set(model.rawValue, forKey: "selectedModel") }
    }

    var hasKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        self.apiKey = Keychain.load()
        let saved = UserDefaults.standard.string(forKey: "selectedModel")
        self.model = ClaudeModel(rawValue: saved ?? "") ?? .opus
    }
}
