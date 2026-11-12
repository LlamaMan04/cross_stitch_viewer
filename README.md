# StitchScope

StitchScope is a cross-platform Flutter application for viewing and working through cross-stitch patterns. It stores normalized pattern documents locally, renders large grids through a custom viewport renderer, and keeps mutable stitching progress separate from pattern data.

The current viewer slice includes a local pattern library, built-in sample patterns, a zoomable and pannable workspace, symbol and thread inspection, rendering controls, completed-cell tracking, and persistence for progress and viewport settings. Pattern-file importing is planned; the Library import button currently reports that the feature is coming soon.

## Instructions for Build and Use

### Prerequisites

- Flutter SDK with Dart 3.13.7 or newer.
- A configured Flutter target, such as an Android emulator, iOS simulator, desktop host, or connected device.

### Install and run

```shell
flutter pub get
flutter run
```

On first launch, the local SQLite database is created. If the library is empty, the app seeds the representative garden sample pattern. Open **Settings** and select **Load** under **Sample patterns** to add the small, large, and extra-large fixtures.

### Using the app

1. Open a pattern from **Pattern Library**.
2. Pan and zoom the workspace with touch, mouse, trackpad, or wheel input.
3. Use the workspace menu to open renderer settings, the symbol palette, or completion selection.
4. Select cells to mark them complete or incomplete; recent completion changes can be undone.
5. Use the symbol palette to inspect thread and backstitch details.

The **Import pattern** action is currently a placeholder for the planned import workflow.

## Development Environment

The project is a Flutter/Dart application using the following main dependencies:

- Flutter SDK and Dart SDK `^3.13.7`.
- Drift `^2.31.0` for typed SQLite persistence and migrations.
- `sqlite3_flutter_libs` for bundled SQLite libraries on Flutter targets.
- `path` and `path_provider` for locating the application database.
- `flutter_lints`, `flutter_test`, `build_runner`, and `drift_dev` for analysis, testing, and generated database code.

Useful development commands:

```shell
flutter analyze
flutter test
dart format .
flutter build windows
flutter build apk
```

## Project Structure

```text
lib/
  main.dart                         Application entry point
  app/                              Composition root, app shell, fixtures
  domain/                           Pattern and progress contracts
  infrastructure/persistence/       Drift database, migrations, repositories
  presentation/screens/              Library, settings, and workspace screens
  presentation/pattern_renderer/     Camera, viewport, painter, caches, input
test/
  app/                              Fixture tests
  domain/                           Domain contract and validation tests
  infrastructure/                   Database, migration, and repository tests
  presentation/                     Widget, interaction, and renderer tests
docs/                               Architecture and implementation plans
```

`PatternDocument` contains normalized source data such as dimensions, symbols, threads, cells, provenance, regions, and backstitch definitions. `ProgressState` contains user-owned data such as completed coordinates, markers, and the last viewport. Repository interfaces live in `lib/domain/`, while Drift-backed adapters live in `lib/infrastructure/persistence/`.

## Useful Websites to Learn More

- [Flutter documentation](https://docs.flutter.dev/)
- [Dart documentation](https://dart.dev/guides)
- [Drift documentation](https://drift.simonbinder.eu/)
- [Flutter testing documentation](https://docs.flutter.dev/testing)

## Future Work

The following items are planned or still in progress:

- [ ] Import supported pattern files and convert them into normalized documents.
- [ ] Add portable, versioned JSON serialization and import/export codecs.
- [ ] Add parser progress, diagnostics, review, and correction flows.
- [ ] Add pattern rename, delete, duplicate, and export management actions.
- [ ] Validate production persistence and packaging across Android, iOS, Windows, macOS, and Linux.
