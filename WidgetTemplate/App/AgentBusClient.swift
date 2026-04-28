import Foundation
import SwiftUI
import WidgetKit

struct BusEnvelope: Codable {
    var id: String?
    var type: String
    var source: String
    var timestamp: String?
    var correlation_id: String?
    var session_id: String?
    var target: String?
    var payload: [String: JSONValue]
}

indirect enum JSONValue: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .array(try container.decode([JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

@MainActor
final class HermesCompanionModel: ObservableObject {
    @Published var content = WidgetContent.sample
    @Published var connectionStatus = "Disconnected"

    private let store = WidgetContentStore()
    private var webSocket: URLSessionWebSocketTask?
    private let busURL = URL(string: "ws://127.0.0.1:8790/ws")!
    private let hermesURL = URL(string: "http://127.0.0.1:8642/v1/responses")!

    func connect() {
        webSocket?.cancel()
        webSocket = URLSession.shared.webSocketTask(with: busURL)
        webSocket?.resume()
        connectionStatus = "Connected"
        receive()
    }

    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        connectionStatus = "Disconnected"
    }

    private func receive() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(.data(let data)):
                    await self.handle(data)
                    self.receive()
                case .success(.string(let text)):
                    await self.handle(Data(text.utf8))
                    self.receive()
                case .failure:
                    self.connectionStatus = "Disconnected"
                @unknown default:
                    self.receive()
                }
            }
        }
    }

    private func handle(_ data: Data) async {
        guard let wrapper = try? JSONDecoder().decode(WebSocketEnvelope.self, from: data) else { return }
        let envelope = wrapper.envelope
        if envelope.type == "voice.transcription.completed" {
            let transcript = envelope.payload["transcript"]?.stringValue ?? ""
            update(transcript: transcript, assistant: "Pensando...", status: "Hermes")
            await askHermes(transcript: transcript, sessionID: envelope.session_id, correlationID: envelope.correlation_id)
        } else if envelope.type == "agent.option.selected" {
            let option = envelope.payload["option_id"]?.stringValue
            content.selectedOption = option
            content.updatedAt = .now
            saveAndReload()
        }
    }

    private func askHermes(transcript: String, sessionID: String?, correlationID: String?) async {
        do {
            publish(type: "hermes.request.started", sessionID: sessionID, correlationID: correlationID, payload: ["transcript": .string(transcript)])
            let assistantText = try await HermesHTTPClient(url: hermesURL).ask(transcript: transcript)
            update(transcript: transcript, assistant: assistantText, status: "Respuesta")
            publish(type: "hermes.response.completed", sessionID: sessionID, correlationID: correlationID, payload: ["assistant_text": .string(assistantText)])
            publishAgentSession(sessionID: sessionID ?? UUID().uuidString, assistantText: assistantText)
            publish(type: "voice.tts.speak", target: "agent-voice-gateway", sessionID: sessionID, correlationID: correlationID, payload: ["text": .string(assistantText)])
        } catch {
            update(transcript: transcript, assistant: error.localizedDescription, status: "Error")
            publish(type: "hermes.request.failed", sessionID: sessionID, correlationID: correlationID, payload: ["detail": .string(error.localizedDescription)])
        }
    }

    private func publishAgentSession(sessionID: String, assistantText: String) {
        let payload: [String: JSONValue] = [
            "session_id": .string(sessionID),
            "agent_id": .string("hermes-agent"),
            "status": .string("completed"),
            "summary": .string(assistantText),
            "alert": .object(["severity": .string("info"), "mode": .string("pulse"), "color": .string("yellow"), "target": .string("global")]),
            "options": .array([])
        ]
        publish(type: "agent.session.updated", sessionID: sessionID, correlationID: nil, payload: payload)
    }

    private func publish(type: String, target: String? = nil, sessionID: String?, correlationID: String?, payload: [String: JSONValue]) {
        let envelope = BusEnvelope(id: nil, type: type, source: "mac-widget-hermes", timestamp: nil, correlation_id: correlationID, session_id: sessionID, target: target, payload: payload)
        guard let data = try? JSONEncoder().encode(envelope), let text = String(data: data, encoding: .utf8) else { return }
        webSocket?.send(.string(text)) { _ in }
    }

    private func update(transcript: String, assistant: String, status: String) {
        content = WidgetContent(status: status, transcript: transcript, assistantText: assistant, selectedOption: content.selectedOption, updatedAt: .now)
        saveAndReload()
    }

    private func saveAndReload() {
        try? store.save(content)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetTemplateConfig.widgetKind)
    }
}

private struct WebSocketEnvelope: Codable {
    var stream_id: String?
    var envelope: BusEnvelope
}

struct HermesHTTPClient {
    let url: URL

    func ask(transcript: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": "hermes-agent",
            "input": "The following text was transcribed from push-to-talk audio. It may contain ASR errors.\nUser transcript:\n\(transcript)",
            "conversation": "launchpad-voice",
            "store": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        return extractOutputText(from: data)
    }

    private func extractOutputText(from data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return "" }
        var texts: [String] = []
        walk(json, texts: &texts)
        return texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func walk(_ value: Any, texts: inout [String]) {
        if let dict = value as? [String: Any] {
            if dict["type"] as? String == "output_text", let text = dict["text"] as? String {
                texts.append(text)
            }
            dict.values.forEach { walk($0, texts: &texts) }
        } else if let array = value as? [Any] {
            array.forEach { walk($0, texts: &texts) }
        }
    }
}
