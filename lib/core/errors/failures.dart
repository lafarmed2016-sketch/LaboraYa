abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, super.code, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sin conexión a internet'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Error de caché local'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'La solicitud ha tardado demasiado'});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Ha ocurrido un error inesperado'});
}
