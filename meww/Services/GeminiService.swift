//
//  GeminiService.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation
import Combine

/// Google Gemini API(`generateContent`)로 텍스트를 생성한다 — 예: SwiftData에서 뽑은 취향
/// 분석 결과를 바탕으로 한 자연어 추천 문구. Gemini는 Anthropic Messages API와 인증·요청
/// 방식이 달라서 별도로 만든다 — 인증은 헤더가 아니라 URL 쿼리 파라미터(`key=`)로 전달한다.
@MainActor
final class GeminiService: ObservableObject {
    @Published private(set) var isGenerating = false
    @Published private(set) var errorMessage: String?

    private let session = URLSession.shared
    // gemini-2.5-flash는 신규로 발급된 API 키에는 더 이상 열려있지 않아("no longer available
    // to new users") 항상 실패했다 — 현재 권장되는 flash 티어 모델로 바꿨다.
    private let model = "gemini-3.6-flash"

    /// 429(RESOURCE_EXHAUSTED)를 받았을 때 재시도할 최대 횟수 — 초과하면 그대로 실패 처리한다.
    private let maxRetryCount = 2
    /// 재시도 사이에 기다리는 시간.
    private let retryDelay: Duration = .seconds(1)

    /// 실패하면 `errorMessage`를 채우고 `nil`을 돌려준다.
    func generate(prompt: String) async -> String? {
        guard !Secrets.googleGeminiAPIKey.isEmpty else {
            errorMessage = "Google Gemini API 키가 아직 설정되지 않았어요."
            return nil
        }

        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        for attempt in 0...maxRetryCount {
            do {
                return try await fetchResponse(for: prompt)
            } catch let error as GeminiServiceError {
                // 429는 요청이 몰려서 생기는 일시적인 에러라 잠깐 기다렸다 다시 시도해볼
                // 가치가 있다 — 그 외 에러는 재시도해도 똑같이 실패할 뿐이라 바로 끝낸다.
                let isRateLimited = if case .api(let status, _) = error { status == 429 } else { false }
                guard isRateLimited, attempt < maxRetryCount else {
                    errorMessage = error.userMessage
                    return nil
                }
                try? await Task.sleep(for: retryDelay)
            } catch {
                errorMessage = "추천을 생성하는 중 문제가 발생했어요. 다시 시도해주세요."
                return nil
            }
        }

        return nil
    }

    private func fetchResponse(for prompt: String) async throws -> String {
        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )!
        // Gemini는 Authorization 헤더가 아니라 쿼리 파라미터로 키를 받는다.
        components.queryItems = [URLQueryItem(name: "key", value: Secrets.googleGeminiAPIKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GeminiRequest(
                contents: [GeminiContent(role: "user", parts: [GeminiPart(text: prompt)])],
                // "다시 추천받기"를 눌러도 똑같은 목록이 나오지 않도록 다양성을 살짝 올린다.
                generationConfig: GeminiGenerationConfig(temperature: 1.2)
            )
        )

        let (data, urlResponse) = try await session.data(for: request)

        // Gemini는 에러도 200이 아닌 상태 코드 + {"error": {...}} 형태의 유효한 JSON으로
        // 내려준다 — candidates가 옵셔널이라 디코딩만 하면 "성공"해버리고 진짜 원인이
        // 묻히므로, 상태 코드부터 확인해서 실제 에러 메시지를 그대로 보여준다.
        if let httpResponse = urlResponse as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(GeminiErrorEnvelope.self, from: data) {
                throw GeminiServiceError.api(status: httpResponse.statusCode, message: apiError.error.message)
            }
            throw GeminiServiceError.api(status: httpResponse.statusCode, message: nil)
        }

        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw GeminiServiceError.emptyResponse
        }
        return text
    }
}

private enum GeminiServiceError: Error {
    case api(status: Int, message: String?)
    case emptyResponse

    var userMessage: String {
        switch self {
        case .api(let status, let message):
            if status == 429 {
                return "요청이 많아 잠시 후 다시 시도해주세요"
            }
            if let message {
                return "Gemini 오류(\(status)): \(message)"
            }
            return "Gemini 오류(HTTP \(status))가 발생했어요."
        case .emptyResponse:
            return "Gemini가 빈 응답을 보냈어요. 다시 시도해주세요."
        }
    }
}

private struct GeminiErrorEnvelope: Decodable {
    let error: GeminiErrorDetail
}

private struct GeminiErrorDetail: Decodable {
    let code: Int?
    let message: String
    let status: String?
}

// MARK: - Gemini request/response 포맷 (Anthropic Messages API와 구조가 다르다)

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}
