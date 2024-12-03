// ignore_for_file: lines_longer_than_80_chars

/// Represents the possible states of data in a unidirectional data flow architecture.
/// This sealed class hierarchy ensures exhaustive pattern matching when handling
/// different states of data loading and presentation.
sealed class DataState<T, E> {}

/// Initial state before any data loading has begun. 
/// Use this instead of the late keyword.
/// In unidirectional flow, this represents the entry point before any actions
/// have been dispatched.
class Uninitialized<T, E> extends DataState<T, E> {}

/// Represents paginated data with optional next page information.
/// Used for infinite scrolling and pagination patterns in the unidirectional flow.
class Loaded<T, E> extends DataState<T, E> {
  /// Creates a Paged state with the specified data and optional next page URL
  Loaded(this.data, {this.nextUrl});

  /// The current page of loaded data
  final T data;

  /// URL for fetching the next page, null if no more pages
  final Uri? nextUrl;
}

/// Represents paginated data with optional next page information.
/// Used for infinite scrolling and pagination patterns in the unidirectional flow.
class Loading<T, E> extends DataState<T, E> {
  /// Creates a paged state with the specified data and optional next page URL
  Loading(this.data, {this.nextUrl});

  /// The current page of loaded data
  final T data;

  /// URL for fetching the next page, null if no more pages
  final Uri? nextUrl;
}

/// Represents a failed data operation.
/// Used when an action in the flow results in an error.
class Failed<T, E> extends DataState<T, E> {
  /// Creates a Failed state with the specified error
  Failed(this.error);

  /// The error that occurred during the operation
  final E error;
}
