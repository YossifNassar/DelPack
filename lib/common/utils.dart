Set<Set<T>> toGroup<T>(Set<T> set, int chunkSize) {
  assert(chunkSize > 0);
  var canidatesGroups = Set<Set<T>>();
  int cnt = 1;
  var currentSet = new Set<T>();
  for(var c in set) {
    if(cnt == chunkSize) {
      canidatesGroups.add(currentSet);
      currentSet = new Set<T>();
      cnt = 1;
    } else {
      currentSet.add(c);
    }
    cnt++;
  }
  if(currentSet.isNotEmpty) {
    canidatesGroups.add(currentSet);
  }
  return canidatesGroups;
}