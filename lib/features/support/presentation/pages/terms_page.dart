import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Términos y condiciones'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Última actualización: Julio 2026',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            SizedBox(height: 20),
            _Section(
              title: '1. Aceptación',
              content:
                  'Al registrarte y usar LaboraYa, aceptas estos términos y condiciones.',
            ),
            _Section(
              title: '2. Descripción del servicio',
              content:
                  'LaboraYa es una plataforma de conexión entre personas que buscan trabajadores y personas que ofrecen servicios laborales. LaboraYa actúa ÚNICAMENTE como intermediario tecnológico.\n\nLaboraYa NO garantiza la calidad de los trabajadores, no garantiza el pago por servicios, no es empleador de los trabajadores registrados y no se responsabiliza por daños durante la ejecución de trabajos.',
            ),
            _Section(
              title: '3. Registro y cuenta',
              content:
                  '• Debes ser mayor de 18 años\n• La información proporcionada debe ser verídica\n• Eres responsable de mantener la seguridad de tu cuenta\n• No puedes crear múltiples cuentas',
            ),
            _Section(
              title: '4. Uso aceptable',
              content:
                  'Está prohibido:\n• Publicar información falsa\n• Ofrecer o solicitar trabajos ilegales\n• Acosar, discriminar o amenazar a otros usuarios\n• Compartir contenido ofensivo\n• Crear cuentas falsas o suplantar identidades\n• Usar la plataforma para spam',
            ),
            _Section(
              title: '5. Pagos',
              content:
                  'LaboraYa no procesa pagos directamente. Los acuerdos de pago son entre las partes. Recomendamos usar los métodos de pago sugeridos en la plataforma.',
            ),
            _Section(
              title: '6. Calificaciones',
              content:
                  'Las calificaciones deben reflejar experiencias reales. LaboraYa puede eliminar calificaciones con contenido ofensivo o información falsa.',
            ),
            _Section(
              title: '7. Cancelaciones',
              content:
                  'Ambas partes pueden cancelar un acuerdo indicando el motivo. Las cancelaciones frecuentes pueden afectar la reputación del usuario.',
            ),
            _Section(
              title: '8. Suspensión',
              content:
                  'LaboraYa puede suspender o bloquear cuentas por violación de estos términos, reportes comprobados o actividad sospechosa.',
            ),
            _Section(
              title: '9. Seguridad',
              content:
                  '• No adelantes dinero a desconocidos\n• No compartas contraseñas ni códigos\n• Verifica la identidad de la contraparte\n• Utiliza el chat de la plataforma\n• Reporta comportamientos sospechosos\n• Reúnete en lugares seguros',
            ),
            _Section(
              title: '10. Contacto',
              content: 'Para consultas: soporte@laboraya.com',
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
