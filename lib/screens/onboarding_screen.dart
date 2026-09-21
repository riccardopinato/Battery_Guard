import 'package:flutter/material.dart';

import '../services/app_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      await widget.controller.completeOnboarding();
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _IntroPage(accent: scheme.primary),
                  _PermissionPage(controller: widget.controller),
                  _ReliabilityPage(controller: widget.controller),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _page
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _finishing ? null : _next,
                    child: Text(_page == 2 ? 'Inizia' : 'Continua'),
                  ),
                  if (_page < 2)
                    TextButton(
                      onPressed: _finishing ? null : _finish,
                      child: const Text('Salta configurazione'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      icon: Icons.battery_charging_full_rounded,
      accent: accent,
      title: 'Proteggi la ricarica',
      body:
          'Battery Guard controlla livello, temperatura e sessioni di ricarica. Ti avvisa alla soglia scelta, senza account e senza cloud.',
    );
  }
}

class _BasePage extends StatelessWidget {
  const _BasePage({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    this.children = const [],
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 42, 28, 20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Semantics(
            label: title,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 48, color: accent),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final granted = controller.notificationsGranted;

    return _BasePage(
      icon: granted
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded,
      accent: granted ? scheme.primary : scheme.onSurfaceVariant,
      title: 'Consenti gli avvisi',
      body:
          'Le notifiche servono per soglia, temperatura e anomalie anche quando Battery Guard non è aperta.',
      children: [
        if (granted)
          const Chip(
            avatar: Icon(Icons.check_circle_outline_rounded),
            label: Text('Permesso concesso'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: controller.requestNotificationPermission,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Consenti notifiche'),
          ),
      ],
    );
  }
}

class _ReliabilityPage extends StatelessWidget {
  const _ReliabilityPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = controller.reliability;

    return _BasePage(
      icon: Icons.shield_outlined,
      accent: scheme.primary,
      title: 'Mantienilo operativo',
      body: status.oemHint,
      children: [
        OutlinedButton.icon(
          onPressed: controller.openBatterySettings,
          icon: const Icon(Icons.battery_saver_outlined),
          label: const Text('Apri impostazioni batteria'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: controller.config.enabled
              ? null
              : () => controller.setEnabled(true),
          icon: const Icon(Icons.shield_rounded),
          label: Text(
            controller.config.enabled
                ? 'Protezione già attiva'
                : 'Attiva protezione',
          ),
        ),
      ],
    );
  }
}
