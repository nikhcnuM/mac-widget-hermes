# AGENTS.md — mac-widget-hermes

SwiftUI macOS companion app and WidgetKit widget for the Agent Assistant system.

This repo is one child repo inside the multi-repo workspace at
`/Users/carlosledesma/projects/agent-assistant`. Read the workspace-level
`../AGENTS.md` first when working across repos.

## Current Responsibility

`mac-widget-hermes` owns Hermes interaction and the visible desktop companion UI.

The app target is a live process:

- Connects to `agent-bus` WebSocket.
- Consumes `voice.transcription.completed`.
- Calls Hermes at the OpenAI-compatible local API.
- Publishes `hermes.*`, `agent.session.updated`, and `voice.tts.speak`.
- Persists the latest snapshot in the App Group store.

The WidgetKit extension is passive:

- Reads the latest persisted snapshot.
- Renders status/transcript/assistant text.
- Does not open WebSockets.
- Does not call Hermes.
- Does not perform long-running work.

## Source Map

- `project.yml`
  - XcodeGen source of truth.
- `WidgetTemplate/App/`
  - macOS app target.
  - `ContentView.swift`: companion UI.
  - `AgentBusClient.swift`: bus WebSocket client, Hermes HTTP call, event
    publication, App Group persistence.
- `WidgetTemplate/Shared/`
  - Shared model/store/view used by app and widget.
  - `WidgetContent.swift`: current persisted snapshot shape.
  - `WidgetContentStore.swift`: App Group JSON persistence.
  - `WidgetCardView.swift`: shared render surface.
- `WidgetTemplate/Widget/`
  - WidgetKit extension and timeline provider.

## Bus/Hermes Flow

```text
voice.transcription.completed
  -> companion app extracts transcript
  -> POST Hermes /v1/responses
  -> publish hermes.response.completed
  -> publish agent.session.updated
  -> publish voice.tts.speak
  -> persist WidgetContent snapshot
```

Current default endpoints in code:

- Bus WebSocket: `ws://127.0.0.1:8790/ws`
- Hermes: `http://127.0.0.1:8642/v1/responses`

Future iteration should expose these as settings rather than hard-coded values.

## Event Notes

Consumes:

- `voice.transcription.completed`
- `agent.option.selected`

Publishes:

- `hermes.request.started`
- `hermes.response.completed`
- `hermes.request.failed`
- `agent.session.updated`
- `voice.tts.speak`

`agent.session.updated` payload must remain compatible with
`launchpad-system-actions` `AgentSession`.

## Build And Run

This repo uses XcodeGen:

```bash
brew install xcodegen
make generate
make open
```

Then build/run the app in Xcode.

This environment was not build-verified because:

- `xcodegen` was not installed.
- The host reported the Xcode license was not accepted.

Run local verification on a Mac with full Xcode installed.

## Pitfalls

- WidgetKit is not a daemon. Keep WebSockets, Hermes calls, and retries in the
  app target.
- `JSONValue` in `AgentBusClient.swift` is recursive; keep it `indirect`.
- Persisted widget state must remain `Codable`.
- `WidgetCenter.shared.reloadTimelines` belongs in the app after saving a new
  snapshot.
- Avoid storing API keys in the widget. Add secure app-side settings/keychain
  support in a future iteration if Hermes auth becomes necessary.
- This is still first-pass companion code; expect Swift compile fixes once
  XcodeGen/Xcode are available.

## Redelivery and Idempotency (Sprint 3 risk — NOT yet implemented)

`agent-bus` now performs automatic pending-message recovery (`XPENDING` / `XCLAIM`).
If the companion app loses its WebSocket connection while a transcription event was
in flight, the event may be redelivered once the consumer reconnects and the bus
runs recovery.

**Known risk**: the current companion code (`AgentBusClient.swift`) does not deduplicate
events. A redelivered `voice.transcription.completed` with the same `id` or
`correlation_id` will trigger a second Hermes call and a second `agent.session.updated`.

**Mitigation to implement in Sprint 4**:
- Track the last `N` processed `id` values in memory (or in App Group storage).
- Before calling Hermes, check if `envelope.id` or `envelope.correlation_id` was
  recently processed.
- If it was, publish an `agent.session.updated` from the cached snapshot only (skip
  the Hermes call).

Until this is implemented, duplicate Hermes calls are possible during pending recovery
cycles. In practice this only affects sessions where the companion app restarted or
lost its bus connection mid-flight.

## Sibling Repos

- `../agent-bus`: durable bus and event contract.
- `../agent-voice-gateway`: STT/TTS/audio service.
- `../launchpad-system-actions`: physical Launchpad controls and LED renderer.
