import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/monitoring_config.dart';
import '../services/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppController controller;

  String _formatMinutes(int value) {
    final hours = (value ~/ 60).toString().padLeft(2, '0');
    final minutes = (value % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final config = controller.config;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          'Impostazioni',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Protezione',
          children: [
            SwitchListTile.adaptive(
              title: const Text('Battery Guard attivo'),
              subtitle: const Text('Mantiene il monitoraggio anche con schermo spento.'),
              value: config.enabled,
              onChanged: controller.setEnabled,
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Soglia di ricarica'),
              subtitle: Text('Avviso al ${config.targetLevel}%'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _chooseTarget(context, config),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Temperatura massima'),
              subtitle: Text('${config.temperatureThresholdC.toStringAsFixed(0)} °C'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Slider(
                min: 38,
                max: 50,
                divisions: 12,
                label: '${config.temperatureThresholdC.toStringAsFixed(0)} °C',
                value: config.temperatureThresholdC.clamp(38, 50).toDouble(),
                onChanged: (value) {
                  controller.setTemperatureThreshold(value.roundToDouble());
                },
              ),
            ),
            SwitchListTile.adaptive(
              title: const Text('Avvisa al 100%'),
              subtitle: const Text('Avviso aggiuntivo quando la carica è completa.'),
              value: config.notifyFull,
              onChanged: (value) => controller.updateConfig(config.copyWith(notifyFull: value)),
            ),
            SwitchListTile.adaptive(
              title: const Text('Avvisa se il cavo viene scollegato'),
              value: config.notifyUnplugged,
              onChanged: (value) => controller.updateConfig(config.copyWith(notifyUnplugged: value)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Modalità notte',
          children: [
            SwitchListTile.adaptive(
              title: const Text('Silenzia gli avvisi di notte'),
              subtitle: const Text('Le notifiche restano visibili, ma senza suono o vibrazione.'),
              value: config.nightMode,
              onChanged: (value) => controller.updateConfig(config.copyWith(nightMode: value)),
            ),
            if (config.nightMode) ...[
              const Divider(height: 1),
              ListTile(
                title: const Text('Inizio'),
                trailing: Text(_formatMinutes(config.nightStartMinutes)),
                onTap: () => _pickTime(context, start: true),
              ),
              ListTile(
                title: const Text('Fine'),
                trailing: Text(_formatMinutes(config.nightEndMinutes)),
                onTap: () => _pickTime(context, start: false),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Affidabilità e notifiche',
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Permesso notifiche'),
              subtitle: Text(controller.notificationsGranted ? 'Concesso' : 'Da concedere'),
              trailing: controller.notificationsGranted
                  ? const Icon(Icons.check_circle_outline_rounded)
                  : FilledButton.tonal(
                      onPressed: controller.requestNotificationPermission,
                      child: const Text('Consenti'),
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.battery_saver_outlined),
              title: const Text('Impostazioni batteria Android'),
              subtitle: const Text('Utile sui telefoni che limitano i servizi in background.'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: controller.openBatterySettings,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.volume_up_outlined),
              title: const Text('Prova avviso'),
              subtitle: const Text('Invia una notifica di test.'),
              onTap: controller.testAlert,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Informazioni',
          children: const [
            ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Solo dati locali'),
              subtitle: Text('Nessun account, cloud o invio dei dati della batteria.'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Cosa fa Battery Guard'),
              subtitle: Text('Ti avvisa quando raggiungi la soglia scelta. Android non consente a una normale app di interrompere fisicamente la ricarica.'),
            ),
            Divider(height: 1),
            ListTile(
              title: Text('Versione'),
              trailing: Text('0.1.0'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _chooseTarget(BuildContext context, MonitoringConfig config) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soglia di ricarica', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              for (final level in const [80, 85, 90, 100])
                ListTile(
                  title: Text('$level%'),
                  trailing: level == config.targetLevel
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, level);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null) await controller.setTargetLevel(value);
  }

  Future<void> _pickTime(BuildContext context, {required bool start}) async {
    final config = controller.config;
    final minutes = start ? config.nightStartMinutes : config.nightEndMinutes;
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (value == null) return;
    final total = value.hour * 60 + value.minute;
    await controller.updateConfig(
      start
          ? config.copyWith(nightStartMinutes: total)
          : config.copyWith(nightEndMinutes: total),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
