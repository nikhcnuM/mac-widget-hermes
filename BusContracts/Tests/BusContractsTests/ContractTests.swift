import XCTest
@testable import BusContracts

/// Locates ``agent-bus/contracts`` from the workspace root, regardless of how
/// ``swift test`` was invoked.
private func contractsDirectory() -> URL {
    let here = URL(fileURLWithPath: #filePath)
    // Tests/BusContractsTests/ContractTests.swift -> .. up 4 = mac-widget-hermes/
    let widgetRepo = here
        .deletingLastPathComponent() // BusContractsTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // BusContracts
        .deletingLastPathComponent() // mac-widget-hermes
    return widgetRepo.deletingLastPathComponent().appendingPathComponent("agent-bus/contracts")
}

private func loadFixture(_ typeName: String) throws -> Data {
    let url = contractsDirectory()
        .appendingPathComponent("fixtures")
        .appendingPathComponent("\(typeName).json")
    return try Data(contentsOf: url)
}

private func loadFixtureObject(_ typeName: String) throws -> [String: Any] {
    let data = try loadFixture(typeName)
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dict = object as? [String: Any] else {
        throw XCTSkip("fixture \(typeName) is not a JSON object")
    }
    return dict
}

final class EnvelopeDecodingTests: XCTestCase {
    private static let allTypes = [
        "voice.ptt.start",
        "voice.ptt.stop",
        "voice.ptt.cancel",
        "voice.tts.speak",
        "voice.recording.started",
        "voice.recording.stopped",
        "voice.recording.cancelled",
        "voice.transcription.completed",
        "voice.transcription.empty",
        "voice.tts.started",
        "voice.tts.completed",
        "voice.tts.failed",
        "hermes.request.started",
        "hermes.response.completed",
        "hermes.request.failed",
        "agent.session.updated",
        "agent.option.selected"
    ]

    func testEveryFixtureDecodesIntoBusEnvelope() throws {
        for typeName in Self.allTypes {
            let data = try loadFixture(typeName)
            let envelope = try JSONDecoder().decode(BusEnvelope.self, from: data)
            XCTAssertEqual(envelope.type, typeName, "envelope.type mismatch for \(typeName)")
            XCTAssertFalse(envelope.id.isEmpty, "envelope.id must not be empty for \(typeName)")
            XCTAssertFalse(envelope.source.isEmpty, "envelope.source must not be empty for \(typeName)")
            XCTAssertFalse(envelope.timestamp.isEmpty, "envelope.timestamp must not be empty for \(typeName)")
        }
    }

    func testEnvelopeRoundTripPreservesSnakeCaseKeys() throws {
        let data = try loadFixture("voice.tts.speak")
        let envelope = try JSONDecoder().decode(BusEnvelope.self, from: data)

        let encoded = try JSONEncoder().encode(envelope)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "voice.tts.speak")
        XCTAssertEqual(object["target"] as? String, "agent-voice-gateway")
        XCTAssertNotNil(object["correlation_id"])
        XCTAssertNotNil(object["session_id"])
        XCTAssertNil(object["correlationId"], "Codable must not auto-convert correlation_id to correlationId")
        XCTAssertNil(object["sessionId"], "Codable must not auto-convert session_id to sessionId")
    }

    func testCommandsRequireTargetAddressedToVoiceGateway() throws {
        for typeName in ["voice.ptt.start", "voice.ptt.stop", "voice.ptt.cancel", "voice.tts.speak"] {
            let envelope = try JSONDecoder().decode(BusEnvelope.self, from: try loadFixture(typeName))
            XCTAssertEqual(envelope.target, "agent-voice-gateway", "command \(typeName) must target agent-voice-gateway")
        }
    }
}

final class ConsumedPayloadTests: XCTestCase {
    func testVoiceTranscriptionCompletedPayloadDecodes() throws {
        let dict = try loadFixtureObject("voice.transcription.completed")
        let payloadData = try JSONSerialization.data(withJSONObject: dict["payload"] as Any)
        let payload = try JSONDecoder().decode(VoiceTranscriptionCompletedPayload.self, from: payloadData)
        XCTAssertFalse(payload.transcript.isEmpty)
        XCTAssertFalse(payload.session_id.isEmpty)
    }

    func testAgentOptionSelectedPayloadDecodes() throws {
        let dict = try loadFixtureObject("agent.option.selected")
        let payloadData = try JSONSerialization.data(withJSONObject: dict["payload"] as Any)
        let payload = try JSONDecoder().decode(AgentOptionSelectedPayload.self, from: payloadData)
        XCTAssertEqual(payload.option_id, "ack")
        XCTAssertEqual(payload.selected_control, "top_1")
    }

    func testAgentOptionSelectedRequiresOptionId() throws {
        let dict = try loadFixtureObject("agent.option.selected")
        var payload = (dict["payload"] as? [String: Any]) ?? [:]
        payload.removeValue(forKey: "option_id")
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        XCTAssertThrowsError(try JSONDecoder().decode(AgentOptionSelectedPayload.self, from: payloadData))
    }
}

final class PublishedPayloadTests: XCTestCase {
    func testHermesRequestStartedRoundTrip() throws {
        let payload = HermesRequestStartedPayload(transcript: "Run the tests")
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["transcript"] as? String, "Run the tests")
    }

    func testHermesResponseCompletedRoundTrip() throws {
        let payload = HermesResponseCompletedPayload(assistant_text: "Tests passed.")
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["assistant_text"] as? String, "Tests passed.")
        XCTAssertNil(object["assistantText"])
    }

    func testHermesRequestFailedRoundTrip() throws {
        let payload = HermesRequestFailedPayload(detail: "boom")
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["detail"] as? String, "boom")
    }

    func testVoiceTtsSpeakRoundTrip() throws {
        let payload = VoiceTtsSpeakPayload(text: "Build lista.")
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["text"] as? String, "Build lista.")
    }

    func testAgentSessionUpdatedFixtureDecodesAndPreservesOptionIds() throws {
        let dict = try loadFixtureObject("agent.session.updated")
        let payloadData = try JSONSerialization.data(withJSONObject: dict["payload"] as Any)
        let payload = try JSONDecoder().decode(AgentSessionUpdatedPayload.self, from: payloadData)
        XCTAssertEqual(payload.session_id, "ptt-20260428-160000-000000")
        XCTAssertEqual(payload.agent_id, "hermes-agent")
        XCTAssertEqual(payload.options.map(\.option_id), ["ack", "dismiss"])

        // Re-encode and check we did not silently rename keys.
        let encoded = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNotNil(object["session_id"])
        XCTAssertNotNil(object["agent_id"])
        XCTAssertNil(object["sessionId"])
        XCTAssertNil(object["agentId"])
        let options = try XCTUnwrap(object["options"] as? [[String: Any]])
        XCTAssertNotNil(options.first?["option_id"])
        XCTAssertNil(options.first?["optionId"])
    }
}
