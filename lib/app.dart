import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

class BatteryGuardApp extends StatefulWidget {
  const BatteryGuardApp({super.key});

  @override
  State<BatteryGuardApp> createState() => _BatteryGuardAppState();
}

class _BatteryGuardAppState extends State<BatteryGuardApp>
    with WidgetsBindingObserver {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AppController()..initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshSnapshot();
      _controller.refreshHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _MainShell(controller: _controller);
        },
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({required this.controller});

  final AppController controller;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(controller: widget.controller),
      InsightsScreen(controller: widget.controller),
      HistoryScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.battery_5_bar_outlined),
            selectedIcon: Icon(Icons.battery_5_bar_rounded),
            label: 'Batteria',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Storico',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
