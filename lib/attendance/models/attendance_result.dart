/// Generic wrapper for an attendance API response so the UI can read
/// `success`, the server `message`, and the parsed `data` in one place.
class AttendanceResult<T> {
  final bool success;
  final String message;
  final T? data;

  AttendanceResult({
    required this.success,
    required this.message,
    this.data,
  });
}
