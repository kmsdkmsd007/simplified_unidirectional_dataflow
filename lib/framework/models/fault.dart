/// Represents an error condition in the unidirectional data flow.
/// Used to provide consistent error handling and messaging throughout the
/// application.
///
/// Note thay this could represent an [Error], [Exception] or even other objects
/// The best way to represent a fault is as an Algebraic Data Type of Exception,
/// Error, or other objects that represent a failure state.
/// https://www.christianfindlay.com/blog/dart-algebraic-data-types
typedef Fault = ({
  /// Human-readable error message
  String message,
  //Note: you can inlude other information like status codes, and strack trace
  //here
});
