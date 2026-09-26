/// Runs [worker] over [items] with at most [concurrency] in flight at once,
/// preserving input order in the result regardless of completion order.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) worker,
) async {
  if (items.isEmpty) return [];
  final results = List<R?>.filled(items.length, null);
  var next = 0;
  Future<void> runWorker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await worker(items[index]);
    }
  }

  final workerCount = concurrency < items.length ? concurrency : items.length;
  await Future.wait(List.generate(workerCount, (_) => runWorker()));
  return results.cast<R>();
}
