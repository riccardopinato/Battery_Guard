import 'generated/app_localizations.dart';

String localizedBatteryStatus(AppLocalizations l10n, String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'in carica' || value == 'charging') {
    return l10n.statusCharging;
  }
  if (value == 'in uso' || value == 'discharging') {
    return l10n.statusDischarging;
  }
  if (value == 'carica completa' || value == 'full') {
    return l10n.statusFull;
  }
  if (value == 'non in carica' || value == 'not charging') {
    return l10n.statusNotCharging;
  }
  return l10n.statusUnknown;
}

String localizedBatteryHealth(AppLocalizations l10n, String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'buona' || value == 'good') return l10n.healthGood;
  if (value == 'surriscaldata' || value == 'overheat') {
    return l10n.healthOverheat;
  }
  if (value == 'critica' || value == 'dead') return l10n.healthCritical;
  if (value == 'sovratensione' || value == 'over voltage') {
    return l10n.healthOverVoltage;
  }
  if (value == 'anomalia' || value == 'failure') {
    return l10n.healthFailure;
  }
  if (value == 'troppo fredda' || value == 'cold') {
    return l10n.healthCold;
  }
  return l10n.healthUnknown;
}

String localizedPlugType(AppLocalizations l10n, String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'caricatore ac' || value == 'ac charger' || value == 'ac') {
    return l10n.sourceAc;
  }
  if (value == 'usb') return l10n.sourceUsb;
  if (value == 'ricarica wireless' || value == 'wireless charging') {
    return l10n.sourceWireless;
  }
  if (value == 'dock') return l10n.sourceDock;
  if (value == 'nessuno' || value == 'none' || value.isEmpty) {
    return l10n.sourceNone;
  }
  return raw;
}
