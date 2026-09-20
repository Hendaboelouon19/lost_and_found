import 'package:dio/dio.dart';
import 'package:errasoft/core/networking/api_error_model.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static ApiErrorModel handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return const ApiErrorModel(
            message: 'Connection timeout',
          );

        case DioExceptionType.sendTimeout:
          return const ApiErrorModel(
            message: 'Send timeout',
          );

        case DioExceptionType.receiveTimeout:
          return const ApiErrorModel(
            message: 'Receive timeout',
          );

        case DioExceptionType.transformTimeout:
          return const ApiErrorModel(
            message: 'Response processing timeout',
          );

        case DioExceptionType.connectionError:
          return const ApiErrorModel(
            message: 'No internet connection',
          );

        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);

        case DioExceptionType.cancel:
          return const ApiErrorModel(
            message: 'Request cancelled',
          );

        case DioExceptionType.badCertificate:
          return const ApiErrorModel(
            message: 'Bad certificate',
          );

        case DioExceptionType.unknown:
          return const ApiErrorModel(
            message: 'Unknown network error',
          );
      }
    }

    return const ApiErrorModel(
      message: 'Something went wrong',
    );
  }

  static ApiErrorModel _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Something went wrong';

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;
    }

    switch (statusCode) {
      case 400:
        message = message == 'Something went wrong'
            ? 'Bad request'
            : message;
        break;

      case 401:
        message = 'Unauthorized';
        break;

      case 403:
        message = 'Forbidden';
        break;

      case 404:
        message = 'Not found';
        break;

      case 409:
        message = message == 'Something went wrong'
            ? 'Conflict'
            : message;
        break;

      case 422:
        message = message == 'Something went wrong'
            ? 'Invalid data'
            : message;
        break;

      case 500:
        message = 'Internal server error';
        break;
    }

    return ApiErrorModel(
      message: message,
      statusCode: statusCode,
      errors: data is Map<String, dynamic> &&
              data['errors'] is Map<String, dynamic>
          ? data['errors'] as Map<String, dynamic>
          : null,
    );
  }
}