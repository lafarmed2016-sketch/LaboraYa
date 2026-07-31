import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});
  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  int _method = 0; // 0=Yape 1=Plin 2=Tarjeta 3=Efectivo 4=Transferencia
  bool _showQr = false;

  final _methods = const [
    _Method('Yape', '💜', Color(0xFF6B21A8)),
    _Method('Plin', '💙', Color(0xFF0284C7)),
    _Method('Tarjeta', '💳', Color(0xFF1E3A5F)),
    _Method('Efectivo', '💵', Color(0xFF065F46)),
    _Method('Transferencia', '🏦', Color(0xFF374151)),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showQr)
      return _QrScreen(
        method: _methods[_method],
        onBack: () => setState(() => _showQr = false),
      );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _AmountBadge(
                      amount: 'S/ 120.00',
                      label: 'Monto del trabajo',
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Selecciona tu método de pago',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MethodGrid(
                      methods: _methods,
                      selected: _method,
                      onSelect: (i) => setState(() {
                        _method = i;
                      }),
                    ),
                    const SizedBox(height: 28),
                    if (_method == 0 || _method == 1) ...[
                      _DigitalWalletForm(method: _methods[_method]),
                    ] else if (_method == 2) ...[
                      _CardForm(),
                    ] else if (_method == 3) ...[
                      _CashInfo(),
                    ] else ...[
                      _TransferInfo(),
                    ],
                  ],
                ),
              ),
            ),
            _BottomAction(
              method: _methods[_method],
              onPay: () {
                if (_method == 0 || _method == 1) {
                  setState(() => _showQr = true);
                } else {
                  _confirm(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Pago configurado!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se coordinará el pago al finalizar el trabajo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ── Header ──
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F5))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textDark,
            ),
          ),
          const Expanded(
            child: Text(
              'Método de pago',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 11, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  '100% Seguro',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge de monto ──
class _AmountBadge extends StatelessWidget {
  final String amount;
  final String label;
  const _AmountBadge({required this.amount, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid de métodos ──
class _MethodGrid extends StatelessWidget {
  final List<_Method> methods;
  final int selected;
  final void Function(int) onSelect;
  const _MethodGrid({
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: methods.length,
      itemBuilder: (_, i) {
        final m = methods[i];
        final isSelected = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? m.color.withValues(alpha: 0.08)
                  : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? m.color : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 5),
                Text(
                  m.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? m.color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Formulario billetera digital (Yape/Plin) ──
class _DigitalWalletForm extends StatelessWidget {
  final _Method method;
  const _DigitalWalletForm({required this.method});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de ${method.name}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _InputField(
          label: 'Número de teléfono',
          hint: '987 654 321',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: method.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: method.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(method.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagar con ${method.name}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: method.color,
                      ),
                    ),
                    Text(
                      'Se generará un QR para confirmar el pago',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Formulario de tarjeta ──
class _CardForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingresar datos de tarjeta',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        // Logos de tarjetas aceptadas
        Row(
          children: [
            _CardLogo(
              color: const Color(0xFFEB001B),
              text2Color: const Color(0xFFF79E1B),
              isVisa: false,
            ),
            const SizedBox(width: 8),
            _VisaLogo(),
            const SizedBox(width: 8),
            _AELogo(),
          ],
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Número de tarjeta',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InputField(
                label: 'MM/AA',
                hint: '08/28',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InputField(
                label: 'CVV',
                hint: '•••',
                icon: Icons.lock_outline,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InputField(
          label: 'Nombre en la tarjeta',
          hint: 'JUAN PEREZ',
          icon: Icons.person_outline,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 12),
        // Guardar datos checkbox
        Row(
          children: [
            const SizedBox(width: 2),
            Checkbox(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              'Guardar datos para futuros pagos',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardLogo extends StatelessWidget {
  final Color color;
  final Color text2Color;
  final bool isVisa;
  const _CardLogo({
    required this.color,
    required this.text2Color,
    required this.isVisa,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'VISA',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1A1F71),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _AELogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF016FD0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'AMEX',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Info efectivo ──
class _CashInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        children: [
          Text('💵', style: TextStyle(fontSize: 36)),
          SizedBox(height: 10),
          Text(
            'Pago en efectivo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'El trabajador recibirá el pago al completar el trabajo. Coordina el monto exacto antes de comenzar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info transferencia ──
class _TransferInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos bancarios',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _InputField(
          label: 'Banco',
          hint: 'BCP, BBVA, Interbank...',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 12),
        _InputField(
          label: 'Número de cuenta / CCI',
          hint: '00220012300200123456',
          icon: Icons.numbers,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Realiza la transferencia antes del inicio del trabajo y comparte el comprobante en el chat.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Campo de entrada reutilizable ──
class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botón de acción inferior ──
class _BottomAction extends StatelessWidget {
  final _Method method;
  final VoidCallback onPay;

  const _BottomAction({required this.method, required this.onPay});

  String get _label {
    switch (method.name) {
      case 'Yape':
        return 'Pagar con Yape ${method.emoji}';
      case 'Plin':
        return 'Pagar con Plin ${method.emoji}';
      case 'Efectivo':
        return 'Confirmar pago en efectivo';
      case 'Transferencia':
        return 'Guardar datos de transferencia';
      default:
        return 'Pagar S/ 120.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: method.color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              const Text(
                'Pago seguro con LaboraYa',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pantalla QR (Yape/Plin) ──
class _QrScreen extends StatelessWidget {
  final _Method method;
  final VoidCallback onBack;

  const _QrScreen({required this.method, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: onBack,
        ),
        title: Text(
          'Código QR — ${method.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Monto
            Text(
              'S/ 120.00',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: method.color,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Muestra este QR al pagador',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            // QR simulado con CustomPainter
            Center(
              child: Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(188, 188),
                      painter: _QrPainter(),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: method.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          method.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Teléfono
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 18, color: method.color),
                  const SizedBox(width: 10),
                  const Text(
                    '987 654 321',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: '987654321'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Número copiado'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: method.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Copiar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: method.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: method.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirmar pago',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── QR CustomPainter (simulado, patrón de puntos) ──
class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;
    final cell = size.width / 21;

    // Patrón básico de QR simulado — 3 esquinas + puntos aleatorios
    void sq(int col, int row, {double s = 1}) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * cell + 1,
            row * cell + 1,
            cell * s - 2,
            cell * s - 2,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    // Esquina top-left
    for (var i = 0; i < 7; i++) {
      sq(0, i);
      sq(6, i);
    }
    for (var i = 1; i < 6; i++) {
      sq(i, 0);
      sq(i, 6);
    }
    for (var i = 2; i < 5; i++) for (var j = 2; j < 5; j++) sq(i, j);

    // Esquina top-right
    for (var i = 14; i < 21; i++) {
      sq(0, i - 14);
      sq(6, i - 14);
    }
    for (var i = 1; i < 6; i++) {
      sq(i, 0);
      sq(i, 6);
    }
    for (var r = 0; r < 7; r++) sq(14 + r, 0);
    for (var r = 0; r < 7; r++) sq(14 + r, 6);
    for (var r = 2; r < 5; r++) for (var c = 16; c < 19; c++) sq(c, r);

    // Esquina bottom-left
    for (var r = 14; r < 21; r++) sq(0, r);
    for (var r = 14; r < 21; r++) sq(6, r);
    for (var c = 1; c < 6; c++) {
      sq(c, 14);
      sq(c, 20);
    }
    for (var r = 16; r < 19; r++) for (var c = 2; c < 5; c++) sq(c, r);

    // Puntos de datos (patrón simulado)
    final pts = [
      8,
      2,
      9,
      3,
      10,
      2,
      11,
      4,
      12,
      3,
      8,
      5,
      10,
      6,
      11,
      6,
      12,
      5,
      9,
      8,
      10,
      9,
      11,
      8,
      12,
      10,
      8,
      11,
      13,
      11,
      9,
      12,
      8,
      14,
      10,
      14,
      12,
      14,
      9,
      15,
      11,
      16,
      12,
      16,
      13,
      14,
      8,
      17,
      10,
      18,
      11,
      17,
      12,
      18,
      13,
      17,
      14,
      8,
      15,
      9,
      16,
      10,
      15,
      11,
      16,
      12,
      14,
      13,
      15,
      14,
      16,
      15,
      17,
      8,
      18,
      9,
      17,
      10,
      18,
      11,
      19,
      12,
      17,
      14,
      18,
      15,
      20,
      9,
      20,
      11,
      19,
      13,
      20,
      15,
      20,
      17,
      19,
      18,
      20,
      20,
      17,
      20,
      18,
      19,
    ];
    for (var i = 0; i < pts.length - 1; i += 2) sq(pts[i], pts[i + 1]);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Modelo ──
class _Method {
  final String name;
  final String emoji;
  final Color color;
  const _Method(this.name, this.emoji, this.color);
}
