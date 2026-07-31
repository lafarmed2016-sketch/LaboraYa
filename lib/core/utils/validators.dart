/// Validadores centralizados para formularios
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu correo electrónico';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Correo inválido';
    return null;
  }

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu número';
    if (value.length < 9) return 'Número inválido';
    return null;
  }

  static String? budget(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) return 'Monto inválido';
    return null;
  }

  static String? minBudget(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa un monto';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Monto inválido';
    return null;
  }
}
