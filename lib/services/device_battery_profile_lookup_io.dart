import 'dart:convert';
import 'dart:io';

import '../models/device_battery_profile.dart';

const _host = 'phone-specs-api-production.up.railway.app';
const _sourceName = 'Phone Specs API (community)';
const _sourceUrl = 'https://github.com/rinehartwang1979/phone-specs-api';

Future<DeviceBatteryProfile> lookupDeviceBatteryProfile(
  DeviceIdentity identity,
) async {
  if (identity.lookupQuery.isEmpty) {
    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.notFound,
      errorCode: 'DEVICE_IDENTITY_EMPTY',
    );
  }

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(seconds: 8);
  try {
    final searchUri = Uri.https(
      _host,
      '/api/v1/search',
      <String, String>{'q': identity.lookupQuery},
    );
    final searchJson = await _getJson(client, searchUri);
    final candidates = _collectMaps(searchJson).toList(growable: false);
    if (candidates.isEmpty) {
      return DeviceBatteryProfile(
        identity: identity,
        status: DeviceSpecLookupStatus.notFound,
        sourceName: _sourceName,
        sourceUrl: _sourceUrl,
        fetchedAt: DateTime.now(),
        errorCode: 'NO_MATCH',
      );
    }

    candidates.sort(
      (a, b) => _scoreCandidate(b, identity).compareTo(
        _scoreCandidate(a, identity),
      ),
    );
    final best = candidates.first;
    final candidateText = _candidateText(best);
    final modelNeedle = _normalize(identity.model);
    final exactMatch =
        modelNeedle.isNotEmpty && _normalize(candidateText).contains(modelNeedle);
    dynamic details = best;

    final id = _readId(best);
    if (id != null && id.isNotEmpty) {
      try {
        final detailUri = Uri.https(_host, '/api/v1/specs/$id');
        details = await _getJson(client, detailUri);
      } catch (_) {
        details = best;
      }
    }

    final capacity = _extractCapacity(details);
    final power = _extractChargePower(details);
    if (capacity == null) {
      return DeviceBatteryProfile(
        identity: identity,
        status: DeviceSpecLookupStatus.notFound,
        sourceName: _sourceName,
        sourceUrl: _sourceUrl,
        sourceConfidence: exactMatch ? 'medium' : 'low',
        exactMatch: exactMatch,
        matchedDeviceName: _displayName(best),
        fetchedAt: DateTime.now(),
        errorCode: 'BATTERY_CAPACITY_NOT_FOUND',
      );
    }

    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.found,
      nominalCapacityMah: capacity.nominal,
      typicalCapacityMah: capacity.typical ?? capacity.fallback,
      maxChargePowerW: power,
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
      sourceConfidence: exactMatch ? 'medium' : 'low',
      exactMatch: exactMatch,
      matchedDeviceName: _displayName(best),
      fetchedAt: DateTime.now(),
    );
  } on SocketException {
    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.error,
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
      fetchedAt: DateTime.now(),
      errorCode: 'NETWORK_UNAVAILABLE',
    );
  } on HttpException {
    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.error,
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
      fetchedAt: DateTime.now(),
      errorCode: 'HTTP_ERROR',
    );
  } on FormatException {
    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.error,
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
      fetchedAt: DateTime.now(),
      errorCode: 'INVALID_RESPONSE',
    );
  } catch (_) {
    return DeviceBatteryProfile(
      identity: identity,
      status: DeviceSpecLookupStatus.error,
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
      fetchedAt: DateTime.now(),
      errorCode: 'LOOKUP_FAILED',
    );
  } finally {
    client.close(force: true);
  }
}

Future<dynamic> _getJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.headers
    ..set(HttpHeaders.acceptHeader, 'application/json')
    ..set(HttpHeaders.userAgentHeader, 'BatteryGuard/1.8');
  final response = await request.close().timeout(const Duration(seconds: 10));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  final body = await utf8.decoder.bind(response).join();
  return jsonDecode(body);
}

Iterable<Map<String, dynamic>> _collectMaps(dynamic node) sync* {
  if (node is Map) {
    final map = node.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    yield map;
    for (final value in map.values) {
      yield* _collectMaps(value);
    }
  } else if (node is List) {
    for (final value in node) {
      yield* _collectMaps(value);
    }
  }
}

int _scoreCandidate(Map<String, dynamic> map, DeviceIdentity identity) {
  final haystack = _normalize(_candidateText(map));
  var score = 0;
  final model = _normalize(identity.model);
  final manufacturer = _normalize(identity.manufacturer);
  final brand = _normalize(identity.brand);
  if (model.isNotEmpty && haystack.contains(model)) score += 100;
  if (manufacturer.isNotEmpty && haystack.contains(manufacturer)) score += 30;
  if (brand.isNotEmpty && haystack.contains(brand)) score += 20;
  for (final token in model.split(' ')) {
    if (token.length >= 2 && haystack.contains(token)) score += 5;
  }
  return score;
}

String _candidateText(Map<String, dynamic> map) {
  final parts = <String>[];
  for (final key in const [
    'name',
    'model',
    'title',
    'brand',
    'manufacturer',
    'device',
    'slug',
    'id',
    '_id',
  ]) {
    final value = map[key];
    if (value != null) parts.add(value.toString());
  }
  if (parts.isEmpty) parts.add(jsonEncode(map));
  return parts.join(' ');
}

String _displayName(Map<String, dynamic> map) {
  for (final key in const ['name', 'title', 'model']) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return _candidateText(map);
}

String? _readId(Map<String, dynamic> map) {
  for (final key in const ['id', '_id', 'slug', 'phone_id', 'device_id']) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

class _CapacityResult {
  const _CapacityResult({
    this.nominal,
    this.typical,
    this.fallback,
  });

  final int? nominal;
  final int? typical;
  final int? fallback;
}

_CapacityResult? _extractCapacity(dynamic node) {
  int? nominal;
  int? typical;
  int? fallback;

  void visit(dynamic value, String path) {
    if (value is Map) {
      value.forEach((key, child) {
        visit(child, '$path/${key.toString().toLowerCase()}');
      });
      return;
    }
    if (value is List) {
      for (final child in value) {
        visit(child, path);
      }
      return;
    }

    final pathLower = path.toLowerCase();
    final relevant = pathLower.contains('battery') ||
        pathLower.contains('capacity');
    if (!relevant) return;

    final values = <int>[];
    if (value is num) {
      values.add(value.round());
    } else if (value is String) {
      for (final match in RegExp(
        r'(\d{3,5})(?:\s*mah)?',
        caseSensitive: false,
      ).allMatches(value)) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null) values.add(parsed);
      }
    }

    for (final candidate in values) {
      if (candidate < 500 || candidate > 30000) continue;
      if (pathLower.contains('typical')) {
        typical ??= candidate;
      } else if (pathLower.contains('nominal') ||
          pathLower.contains('rated')) {
        nominal ??= candidate;
      } else {
        fallback ??= candidate;
      }
    }
  }

  visit(node, '');
  if (nominal == null && typical == null && fallback == null) return null;
  return _CapacityResult(
    nominal: nominal,
    typical: typical,
    fallback: fallback,
  );
}

double? _extractChargePower(dynamic node) {
  double? best;

  void visit(dynamic value, String path) {
    if (value is Map) {
      value.forEach((key, child) {
        visit(child, '$path/${key.toString().toLowerCase()}');
      });
      return;
    }
    if (value is List) {
      for (final child in value) {
        visit(child, path);
      }
      return;
    }
    final p = path.toLowerCase();
    if (!(p.contains('charg') && (p.contains('power') || p.contains('watt')))) {
      return;
    }
    final values = <double>[];
    if (value is num) {
      values.add(value.toDouble());
    } else if (value is String) {
      for (final match in RegExp(
        r'(\d{1,3}(?:\.\d+)?)\s*w',
        caseSensitive: false,
      ).allMatches(value)) {
        final parsed = double.tryParse(match.group(1)!);
        if (parsed != null) values.add(parsed);
      }
    }
    for (final candidate in values) {
      if (candidate > 0 && candidate <= 300) {
        if (best == null || candidate > best!) best = candidate;
      }
    }
  }

  visit(node, '');
  return best;
}
