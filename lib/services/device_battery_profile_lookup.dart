import '../models/device_battery_profile.dart';
import 'device_battery_profile_lookup_stub.dart'
    if (dart.library.io) 'device_battery_profile_lookup_io.dart' as impl;

Future<DeviceBatteryProfile> lookupDeviceBatteryProfile(
  DeviceIdentity identity,
) {
  return impl.lookupDeviceBatteryProfile(identity);
}
