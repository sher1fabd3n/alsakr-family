String formatScore(num value) {
  final doubleValue = value.toDouble();
  final rounded = (doubleValue * 10).round() / 10;
  if ((rounded - rounded.round()).abs() < 0.001) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}

String formatScorePair(num mark, num maxMark) {
  return '${formatScore(mark)} / ${formatScore(maxMark)}';
}
