import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Política de privacidad'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Última actualización: Julio 2026',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            SizedBox(height: 20),
            _Section(
              title: '1. Información que recopilamos',
              content:
                  '• Nombre, apellidos y correo electrónico\n• Número de teléfono\n• Ciudad de residencia\n• Ubicación aproximada (con tu permiso)\n• Fotografías de perfil\n• Documentos de verificación\n• Historial de trabajos y calificaciones\n• Mensajes en la plataforma',
            ),
            _Section(
              title: '2. Uso de la información',
              content:
                  'Utilizamos tu información para:\n• Crear y gestionar tu cuenta\n• Conectar trabajadores con empleadores\n• Mostrar trabajos según tu ubicación\n• Facilitar la comunicación\n• Verificar identidades\n• Mejorar nuestros servicios\n• Enviar notificaciones relevantes',
            ),
            _Section(
              title: '3. Compartición de datos',
              content:
                  'NO vendemos tu información personal. Compartimos datos limitados:\n• Tu perfil público con otros usuarios\n• Datos con proveedores de servicios (hosting, notificaciones)\n• Cuando lo requiera la ley',
            ),
            _Section(
              title: '4. Ubicación',
              content:
                  'Solicitamos acceso a tu ubicación ÚNICAMENTE mientras usas la app, para mostrar trabajos cercanos y calcular distancias. No rastreamos tu ubicación en segundo plano.',
            ),
            _Section(
              title: '5. Seguridad',
              content:
                  'Protegemos tu información mediante:\n• Cifrado de contraseñas\n• Conexiones HTTPS\n• Tokens de sesión seguros\n• Almacenamiento cifrado\n• Acceso restringido a documentos',
            ),
            _Section(
              title: '6. Retención de datos',
              content:
                  'Conservamos tu información mientras tu cuenta esté activa. Al eliminar tu cuenta, los datos personales se eliminan en 30 días.',
            ),
            _Section(
              title: '7. Tus derechos',
              content:
                  'Puedes:\n• Acceder a tus datos personales\n• Corregir información incorrecta\n• Eliminar tu cuenta y datos\n• Retirar consentimientos\n• Exportar tus datos',
            ),
            _Section(
              title: '8. Contacto',
              content:
                  'Para consultas sobre privacidad: privacidad@laboraya.com',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
