import Foundation

/// Envelope shared by every command/event on the agent-bus.
///
/// All field names use snake_case to match the canonical contracts in
/// ``agent-bus/contracts/event-types.json``. Swift's default ``Codable``
/// keyDecodingStrategy preserves the property names as-is, so we declare
/// them in snake_case explicitly.
public struct BusEnvelope: Codable, Equatable {
    public let id: String
    public let type: String
    public let source: String
    public let timestamp: String
    public let correlation_id: String?
    public let session_id: String?
    public let target: String?
    public let payload: JSONValue

    public init(
        id: String,
        type: String,
        source: String,
        timestamp: String,
        correlation_id: String? = nil,
        session_id: String? = nil,
        target: String? = nil,
        payload: JSONValue
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.timestamp = timestamp
        self.correlation_id = correlation_id
        self.session_id = session_id
        self.target = target
        self.payload = payload
    }
}

/// Generic JSON value used for ``BusEnvelope/payload`` so the envelope itself
/// is always decodable regardless of the registered schema.
public indirect enum JSONValue: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case number(Double)
    case integer(Int)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .integer(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .number(value)
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
            return
        }
        self = .array(try container.decode([JSONValue].self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
}

/// Payload of ``voice.transcription.completed``.
public struct VoiceTranscriptionCompletedPayload: Codable, Equatable {
    public let session_id: String
    public let transcript: String

    public init(session_id: String, transcript: String) {
        self.session_id = session_id
        self.transcript = transcript
    }
}

/// Payload of ``voice.tts.speak`` (command sent by the companion).
public struct VoiceTtsSpeakPayload: Codable, Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

/// Payload of ``hermes.request.started``.
public struct HermesRequestStartedPayload: Codable, Equatable {
    public let transcript: String

    public init(transcript: String) {
        self.transcript = transcript
    }
}

/// Payload of ``hermes.response.completed``.
public struct HermesResponseCompletedPayload: Codable, Equatable {
    public let assistant_text: String

    public init(assistant_text: String) {
        self.assistant_text = assistant_text
    }
}

/// Payload of ``hermes.request.failed``.
public struct HermesRequestFailedPayload: Codable, Equatable {
    public let detail: String

    public init(detail: String) {
        self.detail = detail
    }
}

/// Payload of ``agent.option.selected``.
public struct AgentOptionSelectedPayload: Codable, Equatable {
    public let option_id: String
    public let selected_control: String?

    public init(option_id: String, selected_control: String? = nil) {
        self.option_id = option_id
        self.selected_control = selected_control
    }
}

/// Payload of ``agent.session.updated``.
public struct AgentSessionUpdatedPayload: Codable, Equatable {
    public let session_id: String
    public let agent_id: String
    public let status: String
    public let summary: String?
    public let updated_at: String?
    public let alert: AgentAlert?
    public let options: [AgentOption]
}

public struct AgentAlert: Codable, Equatable {
    public let severity: String
    public let mode: String
    public let color: String
    public let target: String
}

public struct AgentOption: Codable, Equatable {
    public let option_id: String
    public let label: String?
    public let color: String?
    public let semantic: String?
    public let position: String?
    public let enabled: Bool?
}
