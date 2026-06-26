import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var keyDraft: String = ""
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-...", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("저장") {
                        settings.apiKey = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        showSaved = true
                    }
                    .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("Anthropic API 키")
                } footer: {
                    Text("키는 이 기기의 키체인에만 저장되며 외부로 전송되지 않습니다. console.anthropic.com 에서 발급받을 수 있습니다.")
                }

                Section {
                    Picker("모델", selection: $settings.model) {
                        ForEach(ClaudeModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                } header: {
                    Text("AI 모델")
                } footer: {
                    Text("정확도가 가장 중요하면 Opus, 속도·비용이 중요하면 Sonnet 또는 Haiku를 고르세요.")
                }

                Section {
                    HStack {
                        Text("현재 상태")
                        Spacer()
                        Text(settings.hasKey ? "사용 준비됨" : "키 필요")
                            .foregroundStyle(settings.hasKey ? .green : .orange)
                    }
                }
            }
            .navigationTitle("설정")
            .onAppear { keyDraft = settings.apiKey }
            .alert("저장되었습니다", isPresented: $showSaved) {
                Button("확인", role: .cancel) { }
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(AppSettings())
}
