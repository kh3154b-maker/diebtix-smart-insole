import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/ble_service.dart';

class ScansScreen extends StatefulWidget {
  // ← استقبل البيانات من home_screen بدل ما نعمل اتصال جديد
  final Stream<InsoleData>? dataStream;
  final bool isConnected;

  const ScansScreen({
    super.key,
    this.dataStream,
    this.isConnected = false,
  });

  @override
  State<ScansScreen> createState() => _ScansScreenState();
}

class _ScansScreenState extends State<ScansScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFoot = 0;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  bool        _bleConnected = false;
  InsoleData? _data;

  double get _heel      => _data?.heel      ?? 0;
  double get _ball      => _data?.ball      ?? 0;
  double get _arch      => _data?.arch      ?? 0;
  double get _bigToe    => _data?.bigToe    ?? 0;
  double get _secondToe => _data?.secondToe ?? 0;

  bool   get _hasAlert      => _data?.pressureAlert == true || _data?.tempAlert == true;
  String get _alertZone     => _data?.pressureZone  ?? '';
  bool   get _isSafe        => _data?.isSafe        ?? true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    _bleConnected = widget.isConnected;

    // استمع للبيانات من الـ stream اللي جاي من home_screen
    widget.dataStream?.listen((data) {
      if (mounted) setState(() {
        _bleConnected = true;
        _data = data;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchFoot(int index) {
    if (index == _selectedFoot) return;
    _animController.reverse().then((_) {
      setState(() => _selectedFoot = index);
      _animController.forward();
    });
  }

  Color _zoneColor(double pressure) {
    if (pressure >= 85) return const Color(0xFFB22222);
    if (pressure >= 70) return const Color(0xFFCD5C5C);
    if (pressure >= 50) return const Color(0xFFE8A0A0);
    if (pressure >= 20) return const Color(0xFFF5C5C5);
    return const Color(0xFFC8E6C9);
  }

  bool _isDanger(double pressure) => pressure >= 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1A56DB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Foot Analysis',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB))),
                  const Spacer(),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bleConnected
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_bleConnected ? 'Live' : 'Offline',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _bleConnected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildFootToggle(),
                    const SizedBox(height: 16),
                    FadeTransition(opacity: _fadeAnim, child: _buildHeatMapCard()),
                    const SizedBox(height: 16),
                    _buildLegend(),
                    const SizedBox(height: 16),
                    _buildPressureBars(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFootToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(30)),
      child: Row(children: [
        Expanded(child: _footTab('Left Foot', 0)),
        Expanded(child: _footTab('Right Foot', 1)),
      ]),
    );
  }

  Widget _footTab(String label, int index) {
    final isSelected = _selectedFoot == index;
    return GestureDetector(
      onTap: () => _switchFoot(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 1))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF1A56DB) : const Color(0xFF6B7280),
            )),
      ),
    );
  }

  Widget _buildHeatMapCard() {
    return Container(
      width: double.infinity, height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: const Color(0xFFF0F4FF)),
            CustomPaint(
              size: const Size(260, 400),
              painter: _DynamicFootPainter(
                isLeft:    _selectedFoot == 0,
                heel:      _heel,
                ball:      _ball,
                arch:      _arch,
                bigToe:    _bigToe,
                secondToe: _secondToe,
                zoneColor: _zoneColor,
              ),
            ),
            SizedBox(
              width: 260, height: 400,
              child: Stack(children: _buildDots()),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    final zones = _selectedFoot == 0
        ? [
            [0.38, 0.18, _bigToe,    'BigToe'],
            [0.58, 0.22, _secondToe, '2nd'],
            [0.32, 0.52, _arch,      'Arch'],
            [0.55, 0.54, _ball,      'Ball'],
            [0.43, 0.76, _heel,      'Heel'],
          ]
        : [
            [0.62, 0.18, _bigToe,    'BigToe'],
            [0.42, 0.22, _secondToe, '2nd'],
            [0.68, 0.52, _arch,      'Arch'],
            [0.45, 0.54, _ball,      'Ball'],
            [0.57, 0.76, _heel,      'Heel'],
          ];

    return zones.map((z) {
      final dx       = (z[0] as double) * 260 - 22;
      final dy       = (z[1] as double) * 400 - 22;
      final pressure = z[2] as double;
      return Positioned(
        left: dx, top: dy,
        child: _SensorDot(
          pressure:    pressure,
          isDanger:    _isDanger(pressure),
          isAlertZone: _alertZone == z[3],
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(const Color(0xFFC8E6C9), 'Safe\n<20%'),
          _legendItem(const Color(0xFFF5C5C5), 'Low\n20-50%'),
          _legendItem(const Color(0xFFE8A0A0), 'Med\n50-70%'),
          _legendItem(const Color(0xFFCD5C5C), 'High\n70-85%'),
          _legendItem(const Color(0xFFB22222), 'Crit\n>85%'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Column(children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6B7280))),
    ]);
  }

  Widget _buildPressureBars() {
    final zones = [
      ['Heel',       _heel],
      ['Ball',       _ball],
      ['Arch',       _arch],
      ['Big Toe',    _bigToe],
      ['Second Toe', _secondToe],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pressure Zones',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827))),
          const SizedBox(height: 12),
          ...zones.map((z) {
            final label    = z[0] as String;
            final pressure = z[1] as double;
            final color    = _zoneColor(pressure);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151))),
                      Text('${pressure.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (pressure / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final color  = _isSafe ? const Color(0xFF166534) : const Color(0xFFDC2626);
    final bg     = _isSafe ? const Color(0xFFF0FFF4) : const Color(0xFFFFF1F1);
    final border = _isSafe ? const Color(0xFF86EFAC) : const Color(0xFFFFCDD2);

    String statusText = _bleConnected ? 'Overall Status: Safe' : 'Overall Status: Offline';
    String bodyText   = _bleConnected
        ? 'All zones within normal pressure limits.'
        : 'Connect to device to see live data.';

    if (_data != null && !_isSafe) {
      statusText = 'Overall Status: Risk';
      bodyText   = _data!.statusSub;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _isSafe ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
                shape: BoxShape.circle),
            child: Icon(_isSafe ? Icons.check : Icons.priority_high,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText, style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 4),
                Text(bodyText, style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF374151), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.history, color: Color(0xFF1A56DB), size: 28),
              const SizedBox(height: 4),
              Text('View History', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827))),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF1A56DB).withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text('Contact Care', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ── Dynamic Foot Painter ──────────────────────────────────────────────────────
class _DynamicFootPainter extends CustomPainter {
  final bool   isLeft;
  final double heel, ball, arch, bigToe, secondToe;
  final Color Function(double) zoneColor;

  const _DynamicFootPainter({
    required this.isLeft, required this.heel, required this.ball,
    required this.arch, required this.bigToe, required this.secondToe,
    required this.zoneColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final solePath = _buildSolePath(w, h);

    canvas.drawPath(solePath, Paint()
      ..color = const Color(0xFFE8D0D0).withOpacity(0.3)
      ..style = PaintingStyle.fill);

    final zones = [
      [isLeft ? 0.43 : 0.57, 0.76, heel],
      [isLeft ? 0.55 : 0.45, 0.54, ball],
      [isLeft ? 0.40 : 0.60, 0.45, arch],
      [isLeft ? 0.38 : 0.62, 0.20, bigToe],
      [isLeft ? 0.58 : 0.42, 0.23, secondToe],
    ];

    for (final z in zones) {
      final cx = (z[0] as double) * w;
      final cy = (z[1] as double) * h;
      final color = zoneColor(z[2] as double);
      canvas.save();
      canvas.clipPath(solePath);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.7, height: h * 0.35),
        Paint()..shader = RadialGradient(
          center: Alignment.center, radius: 0.5,
          colors: [color.withOpacity(0.85), color.withOpacity(0.0)],
        ).createShader(Rect.fromCenter(
            center: Offset(cx, cy), width: w * 0.7, height: h * 0.35))
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    canvas.drawPath(solePath, Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  Path _buildSolePath(double w, double h) {
    final path = Path();
    if (isLeft) {
      path.moveTo(w * 0.28, h * 0.05);
      path.cubicTo(w * 0.35, h * 0.02, w * 0.58, h * 0.01, w * 0.72, h * 0.06);
      path.cubicTo(w * 0.82, h * 0.10, w * 0.85, h * 0.18, w * 0.82, h * 0.28);
      path.cubicTo(w * 0.78, h * 0.38, w * 0.72, h * 0.42, w * 0.74, h * 0.55);
      path.cubicTo(w * 0.76, h * 0.68, w * 0.72, h * 0.80, w * 0.65, h * 0.90);
      path.cubicTo(w * 0.60, h * 0.96, w * 0.52, h * 0.99, w * 0.44, h * 0.99);
      path.cubicTo(w * 0.36, h * 0.99, w * 0.28, h * 0.96, w * 0.24, h * 0.90);
      path.cubicTo(w * 0.20, h * 0.83, w * 0.22, h * 0.74, w * 0.20, h * 0.65);
      path.cubicTo(w * 0.18, h * 0.56, w * 0.12, h * 0.50, w * 0.14, h * 0.40);
      path.cubicTo(w * 0.16, h * 0.30, w * 0.22, h * 0.24, w * 0.24, h * 0.16);
      path.cubicTo(w * 0.25, h * 0.10, w * 0.26, h * 0.06, w * 0.28, h * 0.05);
    } else {
      path.moveTo(w * 0.72, h * 0.05);
      path.cubicTo(w * 0.65, h * 0.02, w * 0.42, h * 0.01, w * 0.28, h * 0.06);
      path.cubicTo(w * 0.18, h * 0.10, w * 0.15, h * 0.18, w * 0.18, h * 0.28);
      path.cubicTo(w * 0.22, h * 0.38, w * 0.28, h * 0.42, w * 0.26, h * 0.55);
      path.cubicTo(w * 0.24, h * 0.68, w * 0.28, h * 0.80, w * 0.35, h * 0.90);
      path.cubicTo(w * 0.40, h * 0.96, w * 0.48, h * 0.99, w * 0.56, h * 0.99);
      path.cubicTo(w * 0.64, h * 0.99, w * 0.72, h * 0.96, w * 0.76, h * 0.90);
      path.cubicTo(w * 0.80, h * 0.83, w * 0.78, h * 0.74, w * 0.80, h * 0.65);
      path.cubicTo(w * 0.82, h * 0.56, w * 0.88, h * 0.50, w * 0.86, h * 0.40);
      path.cubicTo(w * 0.84, h * 0.30, w * 0.78, h * 0.24, w * 0.76, h * 0.16);
      path.cubicTo(w * 0.75, h * 0.10, w * 0.74, h * 0.06, w * 0.72, h * 0.05);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _DynamicFootPainter old) =>
      old.heel != heel || old.ball != ball || old.arch != arch ||
      old.bigToe != bigToe || old.secondToe != secondToe || old.isLeft != isLeft;
}

// ── Sensor Dot ────────────────────────────────────────────────────────────────
class _SensorDot extends StatelessWidget {
  final double pressure;
  final bool   isDanger, isAlertZone;

  const _SensorDot({
    required this.pressure,
    required this.isDanger,
    required this.isAlertZone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF166534),
        shape: BoxShape.circle,
        border: Border.all(
          color: isAlertZone ? Colors.yellow : Colors.white,
          width: isAlertZone ? 3 : 2.5,
        ),
        boxShadow: [BoxShadow(
          color: (isDanger ? Colors.red : Colors.green).withOpacity(0.4),
          blurRadius: isAlertZone ? 12 : 4,
          spreadRadius: isAlertZone ? 3 : 0,
        )],
      ),
      child: Center(
        child: isDanger
            ? const Icon(Icons.priority_high, color: Colors.white, size: 20)
            : Text('OK', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}