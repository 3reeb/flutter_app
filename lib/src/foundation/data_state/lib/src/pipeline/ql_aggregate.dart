class QLAggregateOp {
  final String alias;
  final String field;
  final String type; // sum, avg, min, max, count

  const QLAggregateOp({
    required this.alias,
    required this.field,
    required this.type,
  });
}
