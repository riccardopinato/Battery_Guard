import 'package:flutter/material.dart';

import 'ads/free_ad_banner.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/charge_doctor_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/onboarding_screen.dart';
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
  Locale? _localeOverride;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AppController();
    _localeOverride = _controller.localeOverride;
    _controller.addListener(_syncLocaleOverride);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshSnapshot();
      _controller.refreshHistory();
      _controller.refreshReliability();
    }
  }

  void _syncLocaleOverride() {
    final next = _controller.localeOverride;
    if (next == _localeOverride || !mounted) return;
    setState(() => _localeOverride = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_syncLocaleOverride);
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
      locale: _localeOverride,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_controller.onboardingComplete) {
            return OnboardingScreen(controller: _controller);
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
    final l10n = AppLocalizations.of(context);
    final pages = [
      HomeScreen(controller: widget.controller),
      ChargeDoctorScreen(controller: widget.controller),
      InsightsScreen(controller: widget.controller),
      HistoryScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];

    final showAds =
        !widget.controller.premium.loading && !widget.controller.premium.isPro;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showAds) const FreeAdBanner(),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: MediaQuery.sizeOf(context).width < 480
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.battery_5_bar_outlined),
            selectedIcon: const Icon(Icons.battery_5_bar_rounded),
            label: l10n.navBattery,
          ),
          NavigationDestination(
            icon: const Icon(Icons.science_outlined),
            selectedIcon: const Icon(Icons.science_rounded),
            label: l10n.navDoctor,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.navInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_rounded),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
