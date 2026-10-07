String chargeTestGroupKey({
  required String label,
  required String source,
}) {
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      // Normalize common separators without deleting non-ASCII letters.
      .replaceAll(RegExp(r'[\s\-_/.,:;]+'), ' ')
      .replaceAllMapped(
        RegExp(r'(\d)\s+([a-zA-Z])'),
        (match) => '${match.group(1)}${match.group(2)}',
      )
      .trim();

  final normalizedLabel = normalize(label);
  final normalizedSource = normalize(source);
  return '$normalizedSource|$normalizedLabel';
}
