# Project Guidelines

## Architecture

- This repo is a reusable macOS widget boilerplate, not a finished product app.
- Keep the project split by responsibility:
  - `WidgetTemplate/App/`: the macOS editor app and local preview.
  - `WidgetTemplate/Shared/`: shared model, storage, config, and SwiftUI card view used by both targets.
  - `WidgetTemplate/Widget/`: WidgetKit timeline provider, widget entry view, and extension metadata.
- Preserve the shared rendering pattern: when changing widget UI, prefer updating the shared view in `WidgetTemplate/Shared/WidgetCardView.swift` so the app preview and widget stay aligned.
- Preserve the shared data flow: app writes via `WidgetContentStore`, widget reads from the same App Group-backed store.

## Build And Test

- Project source of truth is `project.yml`. Do not add or edit a checked-in `.xcodeproj`; regenerate it with `make generate`.
- Use `make generate` after changing targets, build settings, bundle identifiers, entitlements, or Info.plists referenced by `project.yml`.
- Use `make open` to generate and open the Xcode project.
- This repo currently has no automated test suite. Do not claim tests passed unless you actually ran a build or test command in an environment with full Xcode.app and `xcodegen` installed.

## Conventions

- Keep the boilerplate clonable: prefer generic names and reusable defaults unless the task is explicitly about customizing a concrete widget.
- If renaming the template, update the template through `scripts/rename-template.sh` or by editing all related identifiers consistently: project name, target names, bundle IDs, widget kind, and App Group.
- Keep App Group usage consistent across app and widget entitlements and Info.plists.
- Prefer small, focused changes. Do not introduce extra dependencies or extra targets unless the task clearly needs them.
- If a change affects onboarding or cloning flow, update `README.md` and link to it instead of duplicating long setup guidance here.

## Environment Notes

- Full Xcode.app is required for real build validation; Command Line Tools alone are not enough for WidgetKit/macOS app builds.
- `xcodegen` is required to generate the project from `project.yml`.
- Signing and App Group configuration are expected to be finalized in Xcode under Signing & Capabilities after cloning or renaming the template.

## Reference

- See `README.md` for cloning, renaming, setup, and customization workflow.