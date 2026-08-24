/// A sealed class representing the outcome of an operation.
///
/// Use [Success] when the operation completes without error,
/// and [Failure] when an error occurred.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  Failure<T>? get failureOrNull => switch (this) {
        Failure() => this as Failure<T>,
        Success() => null,
      };
}

/// Wraps a successful value of type [T].
base class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success(data: $data)';
}

/// Wraps an error [message] describing what went wrong.
base class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;

  @override
  String toString() => 'Failure(message: $message)';
}
