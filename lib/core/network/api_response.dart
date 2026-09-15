class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool isSuccess;

  ApiResponse.success(this.data) : isSuccess = true, message = null;
  ApiResponse.error(this.message) : isSuccess = false, data = null;
}
