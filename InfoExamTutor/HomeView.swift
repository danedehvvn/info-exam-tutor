import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var vm = SolveViewModel()
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    kindPicker
                    imageSection
                    textSection
                    solveButton

                    if let error = vm.errorMessage {
                        errorBanner(error)
                    }

                    if vm.isLoading && vm.answer.isEmpty {
                        loadingView
                    }

                    if !vm.answer.isEmpty {
                        answerSection
                    }
                }
                .padding()
            }
            .navigationTitle("정보처리기사 튜터")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { editorFocused = false }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in vm.pickedImages.append(image) }
                    .ignoresSafeArea()
            }
            .alert("카메라를 쓸 수 없어요", isPresented: $showCameraUnavailable) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("시뮬레이터에는 카메라가 없습니다. 실제 아이폰에서 사용하거나 '사진 추가'로 캡처를 올려주세요.")
            }
        }
    }

    // MARK: - 섹션들

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("문제 유형").font(.subheadline.bold())
            Picker("문제 유형", selection: $vm.kind) {
                ForEach(ProblemKind.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Text("문제 캡처").font(.subheadline.bold())
                Spacer()
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showCameraUnavailable = true
                    }
                } label: {
                    Label("촬영", systemImage: "camera")
                        .font(.subheadline)
                }
                PhotosPicker(selection: $photoItems, maxSelectionCount: 4, matching: .images) {
                    Label("사진 추가", systemImage: "photo.on.rectangle")
                        .font(.subheadline)
                }
            }

            if !vm.pickedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(vm.pickedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Button {
                                    vm.removeImage(at: index)
                                    if photoItems.indices.contains(index) {
                                        photoItems.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .padding(4)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: photoItems) { _, newItems in
            Task { await vm.loadImages(from: newItems) }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("문제 입력 (선택)").font(.subheadline.bold())
            TextEditor(text: $vm.questionText)
                .frame(minHeight: 120)
                .focused($editorFocused)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if vm.questionText.isEmpty {
                        Text("문제를 직접 붙여넣거나, 위에 캡처만 올려도 됩니다.")
                            .foregroundStyle(.secondary)
                            .padding(14)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var solveButton: some View {
        Button {
            editorFocused = false
            vm.solve(settings: settings, history: history)
        } label: {
            HStack {
                if vm.isLoading { ProgressView().tint(.white) }
                Text(vm.isLoading ? "푸는 중…" : "풀이 보기")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(vm.isLoading || !vm.hasInput)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("문제를 분석하고 있어요…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            MarkdownView(text: vm.answer)
                .textSelection(.enabled)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message).font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
        .environmentObject(HistoryStore())
}
