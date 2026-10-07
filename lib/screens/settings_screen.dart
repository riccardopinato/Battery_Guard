import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/privacy_options_tile.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/monitoring_config.dart';
import '../services/app_controller.dart';
import '../widgets/premium_card.dart';

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
    final l10n = AppLocalizations.of(context);
    final config = controller.config;
    final reliability = controller.reliability;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.refreshReliability,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          PremiumCard(controller: controller),
          const SizedBox(height: 14),
          _Section(
            title: l10n.protection,
            children: [
              SwitchListTile.adaptive(
                title: Text(l10n.batteryGuardActive),
                subtitle: Text(l10n.monitoringScreenOff),
                value: config.enabled,
                onChanged: controller.setEnabled,
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.lowerLimit),
                subtitle: Text(l10n.alertAt(config.lowLevel)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseLowLevel(context, config),
              ),
              SwitchListTile.adaptive(
                title: Text(l10n.notifyLowBattery),
                subtitle: Text(l10n.notifyLowBatteryBody),
                value: config.notifyLow,
                onChanged: (value) => controller.updateConfig(
                  config.copyWith(notifyLow: value),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.upperLimit),
                subtitle: Text(l10n.alertAt(config.targetLevel)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseTarget(context, config),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.maxTemperature),
                subtitle: Text(
                  '${config.temperatureThresholdC.toStringAsFixed(0)} °C',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Slider(
                  min: 38,
                  max: 50,
                  divisions: 12,
                  label:
                      '${config.temperatureThresholdC.toStringAsFixed(0)} °C',
                  value:
                      config.temperatureThresholdC.clamp(38, 50).toDouble(),
                  onChanged: (value) {
                    controller.setTemperatureThreshold(value.roundToDouble());
                  },
                ),
              ),
              SwitchListTile.adaptive(
                title: Text(l10n.notifyAt100),
                subtitle: Text(l10n.fullChargeExtraAlert),
                value: config.notifyFull,
                onChanged: (value) => controller.updateConfig(
                  config.copyWith(notifyFull: value),
                ),
              ),
              SwitchListTile.adaptive(
                title: Text(l10n.notifyCableUnplugged),
                value: config.notifyUnplugged,
                onChanged: (value) => controller.updateConfig(
                  config.copyWith(notifyUnplugged: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.reliability,
            children: [
              ListTile(
                leading: Icon(
                  reliability.serviceHealthy
                      ? Icons.shield_rounded
                      : Icons.warning_amber_rounded,
                  color: reliability.serviceHealthy
                      ? scheme.primary
                      : scheme.error,
                ),
                title: Text(l10n.monitoringStatus),
                subtitle: Text(
                  '${_serviceLabel(l10n)} • ${_batteryEventLabel(l10n)}',
                ),
                trailing: reliability.monitoringRequested &&
                        !reliability.serviceHealthy
                    ? FilledButton.tonal(
                        onPressed: controller.repairMonitoring,
                        child: Text(l10n.repairMonitoring),
                      )
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.notifications),
                subtitle: Text(
                  _deliveryLabel(l10n),
                ),
                trailing: reliability.deliveryReady
                    ? const Icon(Icons.check_circle_outline_rounded)
                    : FilledButton.tonal(
                        onPressed: reliability.notificationsGranted
                            ? controller.openNotificationSettings
                            : controller.requestNotificationPermission,
                        child: Text(
                          reliability.notificationsGranted
                              ? l10n.openSystemSettings
                              : l10n.allow,
                        ),
                      ),
                onTap: controller.openNotificationSettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.battery_saver_outlined),
                title: Text(l10n.batteryOptimization),
                subtitle: Text(
                  reliability.batteryOptimizationIgnored
                      ? l10n.unrestrictedDoze
                      : l10n.androidMayLimit,
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: controller.openBatterySettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: Text(reliability.manufacturer),
                subtitle: Text(_oemHint(l10n)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l10n.recheckReliability),
                onTap: controller.refreshReliability,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.volume_up_outlined),
                title: Text(l10n.testAlert),
                subtitle: Text(l10n.sendTestNotification),
                onTap: () async {
                  final delivered = await controller.testAlert();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        delivered
                            ? l10n.testAlertSent
                            : l10n.testAlertBlocked,
                      ),
                    ),
                  );
                  await controller.refreshReliability();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.south_rounded),
                title: Text(l10n.lowSound),
                onTap: () async {
                  final delivered = await controller.testLowAlert();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        delivered ? l10n.testAlertSent : l10n.testAlertBlocked,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.north_rounded),
                title: Text(l10n.highSound),
                subtitle: Text(l10n.soundChannelsHint),
                onTap: () async {
                  final delivered = await controller.testHighAlert();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        delivered ? l10n.testAlertSent : l10n.testAlertBlocked,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.nightMode,
            children: [
              SwitchListTile.adaptive(
                title: Text(l10n.silenceNightAlerts),
                subtitle: Text(l10n.nightAlertsVisible),
                value: config.nightMode,
                onChanged: (value) => controller.updateConfig(
                  config.copyWith(nightMode: value),
                ),
              ),
              if (config.nightMode) ...[
                const Divider(height: 1),
                ListTile(
                  title: Text(l10n.begin),
                  trailing: Text(_formatMinutes(config.nightStartMinutes)),
                  onTap: () => _pickTime(context, start: true),
                ),
                ListTile(
                  title: Text(l10n.end),
                  trailing: Text(_formatMinutes(config.nightEndMinutes)),
                  onTap: () => _pickTime(context, start: false),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.information,
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.language),
                subtitle: Text(_languageLabel(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseLanguage(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(l10n.localOnly),
                subtitle: Text(l10n.localOnlyBody),
              ),
              if (!controller.premium.isPro)
                const PrivacyOptionsTile(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.whatBatteryGuardDoes),
                subtitle: Text(l10n.whatBatteryGuardDoesBody),
              ),

            ],
          ),
        ],
      ),
    );
  }

  String _serviceLabel(AppLocalizations l10n) {
    final reliability = controller.reliability;
    if (!reliability.monitoringRequested) return l10n.monitorNotRequested;
    return reliability.serviceHealthy
        ? l10n.monitorOperational
        : l10n.monitorCheck;
  }

  String _batteryEventLabel(AppLocalizations l10n) {
    final value = controller.reliability.lastBatteryEventAt;
    if (value == null) return l10n.noBatteryEvent;
    final elapsed = DateTime.now().difference(value);
    if (elapsed.inMinutes < 1) return l10n.lastEventNow;
    if (elapsed.inMinutes < 60) {
      return l10n.lastEventMinutes(elapsed.inMinutes);
    }
    return l10n.lastEventHours(elapsed.inHours);
  }

  String _deliveryLabel(AppLocalizations l10n) {
    final reliability = controller.reliability;
    if (!reliability.notificationsGranted) return l10n.permissionMissing;
    if (!reliability.notificationsGloballyEnabled) {
      return l10n.notificationsDisabled;
    }
    if (!reliability.monitorChannelEnabled &&
        reliability.monitoringRequested) {
      return l10n.monitorChannelDisabled;
    }
    if (!reliability.alertChannelEnabled) return l10n.alertChannelDisabled;
    if (!reliability.highChargeChannelEnabled) {
      return l10n.highChargeChannelDisabled;
    }
    if (reliability.lowAlertEnabled &&
        !reliability.lowBatteryChannelEnabled) {
      return l10n.lowBatteryChannelDisabled;
    }
    if (reliability.nightModeEnabled &&
        !reliability.quietChannelEnabled) {
      return l10n.quietChannelDisabled;
    }
    return l10n.deliveryReady;
  }

  String _oemHint(AppLocalizations l10n) {
    final name = controller.reliability.manufacturer.toLowerCase();
    if (name.contains('xiaomi') ||
        name.contains('redmi') ||
        name.contains('poco')) {
      return l10n.oemXiaomiHint;
    }
    if (name.contains('samsung')) return l10n.oemSamsungHint;
    return l10n.oemBackgroundHint;
  }

  String _languageLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (controller.localeOverride?.languageCode) {
      'en' => l10n.english,
      'it' => l10n.italian,
      'es' => l10n.spanish,
      'fr' => l10n.french,
      'de' => l10n.german,
      'pt' => l10n.portuguese,
      _ => l10n.systemLanguage,
    };
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.systemLanguage),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            for (final entry in [
              ('en', l10n.english),
              ('it', l10n.italian),
              ('es', l10n.spanish),
              ('fr', l10n.french),
              ('de', l10n.german),
              ('pt', l10n.portuguese),
            ])
              ListTile(
                title: Text(entry.$2),
                trailing: controller.localeOverride?.languageCode == entry.$1
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, entry.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await controller.setLocaleOverride(
        selected.isEmpty ? null : selected,
      );
    }
  }

  Future<void> _chooseLowLevel(
    BuildContext context,
    MonitoringConfig config,
  ) async {
    final l10n = AppLocalizations.of(context);
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lowerLimit,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (final level in const [10, 15, 20, 25, 30, 35, 40])
                ListTile(
                  title: Text('$level%'),
                  trailing: level == config.lowLevel
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(sheetContext, level);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null) await controller.setLowLevel(value);
  }

  Future<void> _chooseTarget(
    BuildContext context,
    MonitoringConfig config,
  ) async {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.chargingThreshold,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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

  Future<void> _pickTime(
    BuildContext context, {
    required bool start,
  }) async {
    final config = controller.config;
    final minutes =
        start ? config.nightStartMinutes : config.nightEndMinutes;
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ),
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
  const _Section({
    required this.title,
    required this.children,
  });

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
