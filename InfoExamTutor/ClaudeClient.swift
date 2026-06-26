import Foundation

/// Anthropic Messages API 클라이언트 (스트리밍 + 이미지).
/// 공식 Swift SDK가 없어 raw HTTP(URLSession)로 호출한다.
struct ClaudeClient {
    let apiKey: String
    let model: String

    enum ClientError: LocalizedError {
        case missingKey
        case http(Int, String)
        case network(String)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "API 키가 없습니다. 설정 탭에서 키를 입력하세요."
            case .http(let code, let msg):
                return "API 오류 (\(code)): \(msg)"
            case .network(let msg):
                return "네트워크 오류: \(msg)"
            }
        }
    }

    /// 문제를 풀어 스트리밍으로 답을 받는다.
    /// - Parameter onDelta: 도착한 텍스트 조각마다 메인 액터에서 호출된다.
    func solve(
        questionText: String,
        images: [Data],
        kindHint: String,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClientError.missingKey
        }

        // user 메시지 content 블록 구성: 이미지들 + 텍스트
        var content: [[String: Any]] = []
        for img in images {
            content.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": img.base64EncodedString(),
                ],
            ])
        }

        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = trimmed.isEmpty
            ? "첨부한 이미지의 문제를 정보처리기사 실기 기준으로 풀어줘."
            : trimmed
        content.append(["type": "text", "text": "\(kindHint)\n\n\(body)"])

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "stream": true,
            "system": Prompts.system,
            "messages": [["role": "user", "content": content]],
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 120

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ClientError.network("응답을 받지 못했습니다.")
            }

            // 오류 응답이면 본문을 모아서 메시지로 던진다.
            if http.statusCode != 200 {
                var data = Data()
                for try await b in bytes { data.append(b) }
                let raw = String(data: data, encoding: .utf8) ?? ""
                throw ClientError.http(http.statusCode, friendlyError(raw))
            }

            // SSE 파싱: "data: {...}" 라인만 처리한다.
            for try await line in bytes.lines {
                guard line.hasPrefix("data:") else { continue }
                let json = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                guard !json.isEmpty, json != "[DONE]",
                      let d = json.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                      let type = obj["type"] as? String else { continue }

                if type == "content_block_delta",
                   let delta = obj["delta"] as? [String: Any],
                   delta["type"] as? String == "text_delta",
                   let text = delta["text"] as? String {
                    await onDelta(text)
                } else if type == "error",
                          let err = obj["error"] as? [String: Any],
                          let msg = err["message"] as? String {
                    throw ClientError.http(0, msg)
                }
            }
        } catch let e as ClientError {
            throw e
        } catch {
            throw ClientError.network(error.localizedDescription)
        }
    }

    /// 오류 JSON에서 사람이 읽을 메시지를 추출한다.
    private func friendlyError(_ raw: String) -> String {
        if let d = raw.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let err = obj["error"] as? [String: Any],
           let msg = err["message"] as? String {
            return msg
        }
        return raw.isEmpty ? "알 수 없는 오류" : raw
    }
}
