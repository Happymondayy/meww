//
//  PhotoTextScanButton.swift
//  meww
//
//  Created by yunseo on 8/20/26.
//

import SwiftUI
import PhotosUI
import Vision

/// 책 문장을 손으로 다시 옮겨 적는 대신, 사진(카메라로 찍거나 앨범에서 고른) 속 텍스트를
/// Vision으로 읽어와 채워준다 — 물리책엔 복사 버튼이 없어서 사진이 가장 자연스러운 입력
/// 경로다. 음악 가사는 보통 앱 안에서 보고 있는 걸 복사·붙여넣기 하는 게 더 자연스러워서
/// 이 도구는 책 전용으로 둔다(호출부의 `showsPhotoScan` 참고).
struct PhotoTextScanButton: View {
    /// 인식된 텍스트를 돌려준다 — 필드에 그대로 넣을지, 기존 내용에 이어붙일지는 호출부가 정한다.
    var onRecognized: (String) -> Void

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isRecognizing = false
    @State private var recognitionFailed = false

    var body: some View {
        Button {
            showSourceDialog = true
        } label: {
            if isRecognizing {
                ProgressView()
                    .padding(6)
            } else {
                Image(systemName: "text.viewfinder")
                    .font(.body)
                    .foregroundStyle(Color.recordTextSecondary)
                    .padding(6)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .disabled(isRecognizing)
        .confirmationDialog("사진에서 문장 가져오기", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("카메라로 촬영") { showCamera = true }
            }
            Button("사진 보관함에서 선택") { showPhotoPicker = true }
            Button("취소", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                recognize(image)
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .alert("텍스트를 못 찾았어요", isPresented: $recognitionFailed) {
            Button("확인", role: .cancel) {}
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                isRecognizing = true
                defer {
                    isRecognizing = false
                    photoPickerItem = nil
                }
                // `loadTransferable`은 이미 `Data?`를 돌려주기 때문에, 여기에 `try?`를
                // 또 씌우면 옵셔널이 두 겹(`Data??`)이 돼버려서 do/catch로 한 번만 벗긴다.
                do {
                    guard
                        let data = try await newItem.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    else { return }
                    await recognizeAsync(image)
                } catch {
                    recognitionFailed = true
                }
            }
        }
    }

    private func recognize(_ image: UIImage) {
        isRecognizing = true
        Task {
            await recognizeAsync(image)
        }
    }

    private func recognizeAsync(_ image: UIImage) async {
        let text = await TextRecognizer.recognizeText(in: image)
        isRecognizing = false
        if let text {
            onRecognized(text)
        } else {
            recognitionFailed = true
        }
    }
}

/// `Vision`으로 이미지 속 텍스트를 읽어온다 — 온디바이스로 처리되고, 별도 API 키나
/// 네트워크 호출이 필요 없다.
enum TextRecognizer {
    static func recognizeText(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard
                    error == nil,
                    let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: nil)
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: "\n")
                continuation.resume(returning: text.isEmpty ? nil : text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

/// `UIImagePickerController`(카메라)를 SwiftUI에서 쓰기 위한 래퍼 — `PhotosPicker`는
/// 앨범 선택만 지원하고 카메라 촬영은 아직 SwiftUI 네이티브 API가 없다.
struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
