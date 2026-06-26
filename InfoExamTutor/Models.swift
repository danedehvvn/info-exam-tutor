import Foundation

/// 푼 문제 한 건의 기록.
struct SolvedRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let kind: String
    let question: String
    let answer: String

    init(id: UUID = UUID(), date: Date = Date(), kind: String, question: String, answer: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.question = question
        self.answer = answer
    }
}

/// 문제 유형 — 프롬프트에 힌트로 전달해 풀이 방향을 잡는다.
enum ProblemKind: String, CaseIterable, Identifiable {
    case auto = "자동 인식"
    case c = "C 언어"
    case java = "Java"
    case python = "Python"
    case sql = "SQL"
    case theory = "단답형/이론"

    var id: String { rawValue }

    /// 프롬프트에 들어갈 한 줄 힌트.
    var hint: String {
        switch self {
        case .auto:   return "문제 유형은 직접 판단해줘."
        case .c:      return "이 문제는 C 언어 코드 추적 문제일 가능성이 높아."
        case .java:   return "이 문제는 Java 코드 추적/객체지향 문제일 가능성이 높아."
        case .python: return "이 문제는 Python 코드 추적 문제일 가능성이 높아."
        case .sql:    return "이 문제는 SQL/데이터베이스 문제일 가능성이 높아."
        case .theory: return "이 문제는 단답형 또는 이론 문제일 가능성이 높아."
        }
    }
}

/// 사용 가능한 모델 — 정확도/속도/비용 트레이드오프.
enum ClaudeModel: String, CaseIterable, Identifiable {
    case opus   = "claude-opus-4-8"
    case sonnet = "claude-sonnet-4-6"
    case haiku  = "claude-haiku-4-5"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .opus:   return "Opus 4.8 — 가장 정확 (기본)"
        case .sonnet: return "Sonnet 4.6 — 빠르고 저렴"
        case .haiku:  return "Haiku 4.5 — 가장 빠름/저렴"
        }
    }
}
