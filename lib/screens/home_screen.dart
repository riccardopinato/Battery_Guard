import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_controller.dart';
import '../widgets/battery_ring.dart';
import '../widgets/metric_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final config = controller.config;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.refreshSnapshot,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Guard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    Text(
                      config.enabled ? 'Protezione attiva' : 'Protezione disattivata',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: config.enabled ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: config.enabled,
                onChanged: controller.setEnabled,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: BatteryRing(
              level: snapshot.level,
              temperatureC: snapshot.temperatureC,
              isCharging: snapshot.isCharging,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        snapshot.isPlugged ? Icons.power_rounded : Icons.power_off_rounded,
                        color: snapshot.isPlugged ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.isPlugged ? snapshot.plugType : 'Non collegato',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              '${snapshot.status} • salute ${snapshot.health.toLowerCase()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.isPowerSaveMode)
                        const Tooltip(
                          message: 'Risparmio energetico attivo',
                          child: Icon(Icons.energy_savings_leaf_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Avvisami al',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 80, label: Text('80%')),
                        ButtonSegment(value: 85, label: Text('85%')),
                        ButtonSegment(value: 90, label: Text('90%')),
                        ButtonSegment(value: 100, label: Text('100%')),
                      ],
                      selected: {config.targetLevel},
                      onSelectionChanged: (values) {
                        HapticFeedback.selectionClick();
                        controller.setTargetLevel(values.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              MetricCard(
                icon: Icons.thermostat_rounded,
                label: 'Temperatura',
                value: '${snapshot.temperatureC.toStringAsFixed(1)} °C',
                caption: snapshot.temperatureC >= config.temperatureThresholdC
                    ? 'Sopra la soglia impostata'
                    : 'Soglia ${config.temperatureThresholdC.toStringAsFixed(0)} °C',
              ),
              MetricCard(
                icon: Icons.electric_bolt_rounded,
                label: 'Potenza stimata',
                value: '${snapshot.powerW.abs().toStringAsFixed(1)} W',
                caption: '${snapshot.currentMa.abs().toStringAsFixed(0)} mA',
              ),
              MetricCard(
                icon: Icons.speed_rounded,
                label: 'Tensione',
                value: '${snapshot.voltageV.toStringAsFixed(2)} V',
                caption: snapshot.technology,
              ),
              MetricCard(
                icon: Icons.favorite_outline_rounded,
                label: 'Salute',
                value: snapshot.health,
                caption: snapshot.status,
              ),
            ],
          ),
          if (!controller.notificationsGranted) ...[
            const SizedBox(height: 14),
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, color: scheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Consenti le notifiche per ricevere gli avvisi anche a schermo spento.',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.requestNotificationPermission,
                      child: const Text('Consenti'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (controller.lastError case final error?) ...[
            const SizedBox(height: 14),
            Text(
              error,
              style: TextStyle(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
