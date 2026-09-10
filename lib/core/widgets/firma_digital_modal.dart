import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class SignatureStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  SignatureStroke({
    required this.points,
    this.color = const Color(0xFF0F172A),
    this.strokeWidth = 3.5,
  });
}

class FirmaDigitalModal extends StatefulWidget {
  final String title;
  final String description;
  final Function(Uint8List? imageBytes)? onSigned;

  const FirmaDigitalModal({
    super.key,
    this.title = 'Firma Digital de Conformidad',
    this.description = 'Realice su firma con el dedo en el recuadro inferior para autenticar la solicitud o contrato.',
    this.onSigned,
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    return await showModalBottomSheet<Uint8List?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FirmaDigitalModal(
          title: title ?? 'Firma Digital de Conformidad',
          description: description ??
              'Realice su firma con el dedo en el recuadro inferior para autenticar la solicitud o contrato.',
        ),
      ),
    );
  }

  @override
  State<FirmaDigitalModal> createState() => _FirmaDigitalModalState();
}

class _FirmaDigitalModalState extends State<FirmaDigitalModal> {
  final List<SignatureStroke> _strokes = [];
  SignatureStroke? _currentStroke;
  bool _isRendering = false;

  bool get _hasSignature => _strokes.isNotEmpty || _currentStroke != null;

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  Future<Uint8List?> _renderSignatureToBytes() async {
    if (!_hasSignature) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(const Offset(0, 0), const Offset(400, 220)),
    );

    // Fondo blanco transparente/limpio
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 220), bgPaint);

    // Pintar trazos
    for (final stroke in _strokes) {
      _drawStrokeOnCanvas(canvas, stroke);
    }
    if (_currentStroke != null) {
      _drawStrokeOnCanvas(canvas, _currentStroke!);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 220);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes?.buffer.asUint8List();
  }

  void _drawStrokeOnCanvas(Canvas canvas, SignatureStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  Future<void> _confirm() async {
    if (!_hasSignature) return;
    setState(() => _isRendering = true);
    try {
      final bytes = await _renderSignatureToBytes();
      if (mounted) {
        widget.onSigned?.call(bytes);
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Title & Close
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.draw_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            widget.description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Canvas Container
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasSignature ? AppColors.primary : const Color(0xFFE2E8F0),
                width: _hasSignature ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Dotted line & signature hint
                Positioned.fill(
                  child: IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: _DottedLinePainter(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Firme sobre la línea con su dedo',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Gesture Listener for drawing strokes
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = SignatureStroke(
                            points: [details.localPosition],
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        if (_currentStroke != null) {
                          setState(() {
                            _currentStroke!.points.add(details.localPosition);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (_currentStroke != null) {
                          setState(() {
                            _strokes.add(_currentStroke!);
                            _currentStroke = null;
                          });
                        }
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Actions: Clear & Undo
          Row(
            children: [
              TextButton.icon(
                onPressed: _hasSignature ? _clear : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Borrar',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
              TextButton.icon(
                onPressed: _strokes.isNotEmpty ? _undo : null,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text(
                  'Deshacer',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (_hasSignature)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Firma capturada',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Confirm Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_hasSignature && !_isRendering) ? _confirm : null,
              icon: _isRendering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_rounded, size: 20),
              label: Text(
                _isRendering ? 'Procesando...' : 'Confirmar y Firmar',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<SignatureStroke> strokes;
  final SignatureStroke? currentStroke;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, SignatureStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
