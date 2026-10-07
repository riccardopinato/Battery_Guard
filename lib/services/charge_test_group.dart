String chargeTestGroupKey({
  required String label,
  required String source,
}) {
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(
        RegExp(r'(\d)\s+([a-z])'),
        (match) => '${match.group(1)}${match.group(2)}',
      )
      .trim();

  final normalizedLabel = normalize(label);
  final normalizedSource = normalize(source);
  return '$normalizedSource|$normalizedLabel';
}
