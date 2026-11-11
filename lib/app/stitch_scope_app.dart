import 'package:flutter/material.dart';

import '../domain/repositories.dart';
import '../presentation/screens/library_screen.dart';
import '../presentation/screens/settings_screen.dart';
import 'extra_large_sample_pattern_fixture.dart';
import 'large_sample_pattern_fixture.dart';
import 'sample_pattern_fixture.dart';

/// Root Material application configuration for StitchScope.
class StitchScopeApp extends StatelessWidget {
  /// Creates the application shell.
  const StitchScopeApp({
    required this.patternDocuments,
    required this.progress,
    super.key,
  });

  /// Repository used by the library and workspace routes.
  final PatternDocumentRepository patternDocuments;

  /// Repository used for persisted workspace state and render settings.
  final ProgressRepository progress;

  /// Builds the app theme and responsive navigation shell.
  @override
  Widget build(BuildContext context) {
    // Shared theme palette used by the app's screens and navigation.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF356859),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'StitchScope',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _AppShell(patternDocuments: patternDocuments, progress: progress),
    );
  }
}

/// Responsive navigation container shared by compact and wide layouts.
class _AppShell extends StatefulWidget {
  /// Creates the shell that owns the active destination.
  const _AppShell({required this.patternDocuments, required this.progress});

  /// Repository passed to the library screen.
  final PatternDocumentRepository patternDocuments;

  /// Repository passed through to pattern workspaces.
  final ProgressRepository progress;

  /// Creates state for the selected navigation destination.
  @override
  State<_AppShell> createState() => _AppShellState();
}

/// Tracks the selected destination and chooses rail or bottom navigation.
class _AppShellState extends State<_AppShell> {
  /// Index of the currently visible screen.
  int _selectedIndex = 0;

  /// Navigation labels and icons shared by the mobile and desktop layouts.
  static const _destinations = <NavigationDestinationData>[
    NavigationDestinationData(
      label: 'Library',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    NavigationDestinationData(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  /// Builds the responsive screen layout and navigation controls.
  @override
  Widget build(BuildContext context) {
    // Wide layouts use a permanent rail; narrow layouts use bottom navigation.
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    // Keeping both screens mounted preserves each screen's local UI state.
    final screens = <Widget>[
      LibraryScreen(
        patternDocuments: widget.patternDocuments,
        progress: widget.progress,
        seedDocuments: [
          SamplePatternFixture.create(),
          LargeSamplePatternFixture.create(),
          ExtraLargeSamplePatternFixture.create(),
        ],
      ),
      const SettingsScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 28),
                child: Icon(
                  Icons.grid_on_rounded,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                // Render each shared destination as one rail item.
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          // Reuse the same destination definitions in the compact layout.
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  /// Updates the selected screen after a navigation interaction.
  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }
}

/// Display data for one destination in the app navigation.
class NavigationDestinationData {
  /// Creates destination metadata for navigation widgets.
  const NavigationDestinationData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Text label shown with the destination icon.
  final String label;

  /// Icon used when the destination is not selected.
  final IconData icon;

  /// Icon used while the destination is selected.
  final IconData selectedIcon;
}
