# BusContracts (Swift)

Standalone Swift Package that pins the Swift wire shape of the agent-bus
events the macOS companion publishes and consumes against the canonical
JSON fixtures in `../../agent-bus/contracts`.

This package is independent from the XcodeGen project: it does not need
`xcodegen` or an accepted Xcode license. It builds and runs with the
plain Swift toolchain shipped on macOS.

## Run

```bash
cd mac-widget-hermes/BusContracts
swift test
```

## What it covers

- Envelope decoding for every type listed in
  `agent-bus/contracts/event-types.json`.
- Round-trip encoding for the payloads published by the macOS companion
  (`hermes.request.started`, `hermes.response.completed`,
  `hermes.request.failed`, `agent.session.updated`, `voice.tts.speak`),
  asserting that Codable does **not** auto-rename `option_id` to
  `optionId`, `session_id` to `sessionId`, or `agent_id` to `agentId`.
- Decoding for the payloads the companion consumes
  (`voice.transcription.completed`, `agent.option.selected`).
- A negative test that drops `option_id` from `agent.option.selected` and
  asserts decoding fails — that is the field the launchpad runtime keys
  off.

When the canonical contracts change, update the fixtures under
`agent-bus/contracts/`, then run `swift test` here. The tests fail loudly
if a Swift model drifts from the schema.
