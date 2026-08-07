/// A sealed class representing the outcome of an operation.
///
/// Use [Success] when the operation completes without error,
/// and [Failure] when an error occurred.
sealed class Result<T> {
  const Result();
}

/// Wraps a successful value of type [T].
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success(data: $data)';
}

/// Wraps an error [message] describing what went wrong.
final class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;

  @override
  String toString() => 'Failure(message: $message)';
}
