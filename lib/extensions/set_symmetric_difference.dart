extension SetSymmetricDifference<E> on Set<E> {
  Set<E> symmetricDifference(Set<E> other) =>
    difference(other).union(other.difference(this));
}
