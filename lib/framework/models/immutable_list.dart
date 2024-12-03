import 'package:flutter/material.dart';

/// An immutable collection that wraps a List to enforce unidirectional data
/// flow principles. Prevents direct mutations and ensures new instances are
/// created for changes, maintaining a clear state history and predictable data
/// flow.
@immutable
class ImmutableList<T> extends Iterable<T> {
  /// Creates an ImmutableList from an Iterable
  ImmutableList(Iterable<T> innerIterable)
      : _innerUnmodifiableList = List<T>.unmodifiable(innerIterable);

  /// Creates an empty ImmutableList
  const ImmutableList.empty() : _innerUnmodifiableList = const [];

  final List<T> _innerUnmodifiableList;

  /// Computes a hash code based on all elements in the list
  @override
  int get hashCode => Object.hashAll(_innerUnmodifiableList);

  /// Gets an iterator over the elements of the immutable list
  @override
  Iterator<T> get iterator => _innerUnmodifiableList.iterator;

  /// Gets the number of elements in the immutable list
  @override
  int get length => _innerUnmodifiableList.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmutableList<T> &&
          length == other.length &&
          _innerUnmodifiableList.asMap().entries.every(
                (entry) =>
                    entry.value == other._innerUnmodifiableList[entry.key],
              );

  /// Gets the element at the specified index
  /// Throws RangeError if index is out of bounds
  T operator [](int index) => _innerUnmodifiableList[index];

  /// Creates a new ImmutableList with the specified element added to the end
  ImmutableList<T> add(T element) =>
      ImmutableList<T>([..._innerUnmodifiableList, element]);

  /// Creates a new ImmutableList with all specified elements added to the end
  ImmutableList<T> addAll(Iterable<T> elements) =>
      ImmutableList<T>([..._innerUnmodifiableList, ...elements]);

  /// Returns a map associating integer indices with elements
  Map<int, T> asMap() => _innerUnmodifiableList.asMap();

  /// Safely gets an element at the specified index, returning null if out of
  ///  bounds
  T? elementAtOrNull(int index) =>
      index >= 0 && index < length ? _innerUnmodifiableList[index] : null;

  /// Creates a new ImmutableList with elements transformed by the given
  /// function
  @override
  ImmutableList<R> map<R>(R Function(T) toElement) =>
      ImmutableList<R>(_innerUnmodifiableList.map(toElement));

  /// Creates a new ImmutableList with the specified element removed
  ImmutableList<T> remove(T element) =>
      ImmutableList<T>(_innerUnmodifiableList.where((e) => e != element));

  /// Creates a new ImmutableList containing only elements that satisfy the test
  @override
  ImmutableList<T> where(bool Function(T) test) =>
      ImmutableList<T>(_innerUnmodifiableList.where(test));
}

/// Extension methods to create ImmutableList instances from regular Iterables.
/// Provides convenient operators for common transformations while maintaining
/// immutability.
extension ImmutableListExtension<T> on Iterable<T> {
  /// Operator syntax for descending sort
  ImmutableList<T> operator <<(Comparator<T> compare) =>
      ImmutableList([...this]..sort((a, b) => compare(b, a)));

  /// Operator syntax for ascending sort
  ImmutableList<T> operator >>(Comparator<T> compare) =>
      ImmutableList([...this]..sort(compare));

  /// Creates a new sorted ImmutableList using the provided comparison function
  ImmutableList<T> orderBy(int Function(T a, T b) compare) =>
      ImmutableList<T>([...this]..sort(compare));

  /// Converts an Iterable to an ImmutableList
  ImmutableList<T> toImmutableList() => ImmutableList<T>(this);

  /// Operator syntax for converting to ImmutableList
  // ignore: use_to_and_as_if_applicable
  ImmutableList<T> operator ~() => ImmutableList<T>(this);
}
