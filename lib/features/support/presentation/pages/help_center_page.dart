import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FaqItem(
        question: '¿Cómo publico un trabajo?',
        answer:
            'Toca el botón "+" en la barra de navegación, completa el formulario con los datos del trabajo y toca "Publicar trabajo".',
      ),
      _FaqItem(
        question: '¿Cómo me postulo a un trabajo?',
        answer:
            'Busca un trabajo que te interese, toca para ver el detalle y presiona "Postularme". Puedes incluir un mensaje y tu propuesta económica.',
      ),
      _FaqItem(
        question: '¿Cómo funciona el chat?',
        answer:
            'Una vez que te postulas o recibes postulantes, puedes comunicarte por el chat integrado. Ve a la pestaña "Mensajes".',
      ),
      _FaqItem(
        question: '¿Cómo califico a un trabajador o empleador?',
        answer:
            'Después de completar un trabajo, ambas partes pueden calificarse mutuamente con estrellas y un comentario.',
      ),
      _FaqItem(
        question: '¿Cómo verifico mi identidad?',
        answer:
            'Ve a Perfil → Verificación. Sube tu documento de identidad y una selfie. Nuestro equipo lo revisará en 24-48 horas.',
      ),
      _FaqItem(
        question: '¿Cómo elimino mi cuenta?',
        answer:
            'Ve a Perfil → Configuración → "Eliminar mi cuenta". Esta acción es irreversible.',
      ),
      _FaqItem(
        question: '¿LaboraYa cobra comisión?',
        answer:
            'Actualmente LaboraYa es gratuito. Los pagos se acuerdan directamente entre trabajador y empleador.',
      ),
      _FaqItem(
        question: '¿Qué hago si tengo un problema con un usuario?',
        answer:
            'Puedes reportar al usuario desde su perfil o desde el chat. Nuestro equipo revisará el caso.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Centro de ayuda'),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.secondaryLight,
            child: const Column(
              children: [
                Icon(Icons.help_outline, size: 48, color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Preguntas frecuentes',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // FAQs
          ...faqs.map(
            (faq) => ExpansionTile(
              title: Text(
                faq.question,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contact
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Divider(),
                SizedBox(height: 16),
                Text(
                  '¿No encontraste lo que buscas?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Escríbenos a soporte@laboraya.com',
                  style: TextStyle(color: AppColors.primary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
