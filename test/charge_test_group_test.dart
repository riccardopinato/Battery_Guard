import 'package:battery_guard/services/charge_test_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Charge Doctor group normalizes casing and punctuation', () {
    final a = chargeTestGroupKey(
      label: 'USB-C 65 W',
      source: 'AC charger',
    );
    final b = chargeTestGroupKey(
      label: '  usb c 65w  ',
      source: 'ac CHARGER',
    );

    expect(a, b);
  });

  test('Charge Doctor keeps different charger setups separate', () {
    final fast = chargeTestGroupKey(
      label: 'USB-C 65 W',
      source: 'AC charger',
    );
    final slow = chargeTestGroupKey(
      label: 'Travel 20 W',
      source: 'AC charger',
    );

    expect(fast, isNot(slow));
  });

  test('Charge Doctor preserves distinct non-ASCII labels', () {
    final first = chargeTestGroupKey(
      label: '充電器一',
      source: 'AC charger',
    );
    final second = chargeTestGroupKey(
      label: '充電器二',
      source: 'AC charger',
    );

    expect(first, isNot(second));
  });

  test('Charge Doctor keeps different Android sources separate', () {
    final ac = chargeTestGroupKey(
      label: 'Same cable',
      source: 'AC charger',
    );
    final usb = chargeTestGroupKey(
      label: 'Same cable',
      source: 'USB',
    );

    expect(ac, isNot(usb));
  });
}
