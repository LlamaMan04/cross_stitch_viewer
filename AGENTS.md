# Repository Guidelines

## Project Structure

This is a Flutter application written in Dart. App startup is in `lib/main.dart`; app configuration and screens are under `lib/app/` and `lib/presentation/`. Platform-independent contracts live in `lib/domain/`: pattern models, progress models, value objects, JSON serialization, errors, and repository interfaces. Keep mutable user progress separate from imported pattern data. Tests are under `test/`, with domain fixtures in `test/domain/fixtures/`. Platform runner projects are in `android/`, `ios/`, `windows/`, `macos/`, and `linux/`.

## Build, Test, and Development

- `flutter pub get` resolves project dependencies.
- `flutter run` launches the app on an available device or emulator.
- `flutter analyze` runs Dart analysis and the configured Flutter lints.
- `flutter test` runs all unit and widget tests; use `flutter test test/domain` for domain contracts.
- `flutter build <platform>` builds a target, for example `flutter build windows` or `flutter build apk`.

## Coding Style and Naming

Format Dart changes with `dart format .` and follow `analysis_options.yaml` (`flutter_lints`). Use two-space indentation, `lower_snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members. Prefer focused files organized by domain responsibility. Keep domain code free of Flutter, persistence, filesystem, and plugin dependencies. Preserve stable JSON field names and validate decoded data at model or codec boundaries.

## Testing

Tests use `flutter_test` and end in `_test.dart`. Add or update focused tests alongside the affected feature; domain tests belong in `test/domain/`. Keep representative JSON data in `test/domain/fixtures/`. Cover serialization round-trips and invalid inputs when changing domain contracts. No project-wide coverage threshold is configured.

## Commits and Pull Requests

Recent commits use short imperative subjects (for example, “Add comments” and “Basic app scaffold”). Use a concise imperative commit title. PRs should describe the user-visible or architectural change, list validation commands and results, and link relevant issues when available. Include screenshots for UI changes and call out schema or fixture changes that affect domain contracts.

## Architecture Notes

`PatternDocument` represents normalized source data; `ProgressState`, markers, and viewport state represent user data. Keep these graphs independent. Repository interfaces belong in the domain layer; concrete storage adapters should remain outside it.
