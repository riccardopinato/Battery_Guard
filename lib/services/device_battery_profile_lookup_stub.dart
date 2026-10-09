import '../models/device_battery_profile.dart';

Future<DeviceBatteryProfile> lookupDeviceBatteryProfile(
  DeviceIdentity identity,
) async {
  return DeviceBatteryProfile.unsupported(identity);
}
