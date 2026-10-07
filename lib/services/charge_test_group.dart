String chargeTestGroupKey({
  required String label,
  required String source,
}) {
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final normalizedLabel = normalize(label);
  final normalizedSource = normalize(source);
  return '$normalizedSource|$normalizedLabel';
}
