/// Small utility to compute inserts and removals between two ordered id lists.
class MessageListDiff {
  /// Returns a map with 'inserts' and 'removes' as lists of indices.
  ///
  /// Both input lists are expected to contain unique string ids.
  static Map<String, List<int>> computeDiffs(
    List<String> oldIds,
    List<String> newIds,
  ) {
    final removes = <int>[];
    final inserts = <int>[];

    // Removals: indices in oldIds that are not in newIds
    for (int i = 0; i < oldIds.length; i++) {
      if (!newIds.contains(oldIds[i])) removes.add(i);
    }

    // Inserts: indices in newIds that are not in oldIds
    for (int i = 0; i < newIds.length; i++) {
      if (!oldIds.contains(newIds[i])) inserts.add(i);
    }

    return {'inserts': inserts, 'removes': removes};
  }
}
