import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/ble_service.dart';

class TrendsScreen extends StatefulWidget {
  final Stream<InsoleData>? dataStream;
  final bool isConnected;

  const TrendsScreen({
    super.key,
    this.dataStream,
    this.isConnected = false,
  });

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  StreamSubscription? _sub;
  InsoleData? _latest;
  bool _bleConnected = false;

  // Temperature history (last 7 readings)
  final List<double> _tempHistory = [];
  final List<String> _tempLabels  = [];

  // Steps history per session
  int _sessionSteps = 0;

  @override
  void initState() {
    super.initState();
    _bleConnected = widget.isConnected;

    _sub = widget.dataStream?.listen((data) {
      if (!mounted) return;
      setState(() {
        _latest       = data;
        _bleConnected = true;
        _sessionSteps = data.steps;

        // Add temp to history max every 10s
        if (_tempHistory.length < 7) {
          _tempHistory.add(data.tempC > 0 ? data.tempC : 36.5);
          final now = DateTime.now();
          _tempLabels.add('${now.hour}:${now.minute.toString().padLeft(2, '0')}');
        } else {
          _tempHistory.removeAt(0);
          _tempLabels.removeAt(0);
          _tempHistory.add(data.tempC > 0 ? data.tempC : 36.5);
          final now = DateTime.now();
          _tempLabels.add('${now.hour}:${now.minute.toString().padLeft(2, '0')}');
        }
      });
    });

    // Default temp history if no data
    if (_tempHistory.isEmpty) {
      _tempHistory.addAll([36.4, 36.6, 36.8, 36.5, 36.7, 36.9, 36.6]);
      _tempLabels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  double get _steps     => (_latest?.steps ?? 0).toDouble();
  double get _stepsGoal => 6000;
  double get _stepsRatio => (_steps / _stepsGoal).clamp(0.0, 1.0);
  String get _stepsStr  => _latest != null
      ? _latest!.steps.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
      : '--';

  double get _tempC     => _latest?.tempC   ?? 0;
  double get _avgTemp   => _tempHistory.isEmpty ? 36.6
      : _tempHistory.reduce((a, b) => a + b) / _tempHistory.length;

  double get _heel      => _latest?.heel      ?? 0;
  double get _ball      => _latest?.ball      ?? 0;
  double get _arch      => _latest?.arch      ?? 0;
  double get _bigToe    => _latest?.bigToe    ?? 0;
  double get _secondToe => _latest?.secondToe ?? 0;
  double get _totalPressure => _heel + _ball + _arch + _bigToe + _secondToe;

  bool   get _isSafe    => _latest?.isSafe    ?? true;
  bool   get _tempAlert => _latest?.tempAlert ?? false;
  bool   get _fallDet   => _latest?.fallDetected ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1A56DB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Trends and Insights',
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
                      style: GoogleFonts.poppins(fontSize: 12,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalized monitoring for your health\njourney.',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    _buildStepsCard(),
                    const SizedBox(height: 16),

                    _buildInsightCard(),
                    const SizedBox(height: 16),

                    _buildWeeklyTempCard(),
                    const SizedBox(height: 16),

                    _buildPressureCard(),
                    const SizedBox(height: 16),

                    _buildAlertSummaryCard(),
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

  // ── STEPS CARD ──────────────────────────────────────────────────────────────
  Widget _buildStepsCard() {
    final pct = (_stepsRatio * 100).toInt();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Steps', style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
          Text('TODAY', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF), letterSpacing: 1)),
          const SizedBox(height: 24),

          Center(
            child: SizedBox(
              width: 160, height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160, height: 160,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      child: CircularProgressIndicator(
                        value: _stepsRatio,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _stepsRatio >= 1.0
                              ? const Color(0xFF166534)
                              : const Color(0xFF1A56DB),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_stepsStr, style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                    Text('Steps', style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF9CA3AF))),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _stepsRatio >= 1.0
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _bleConnected
                    ? '$pct% of Daily Goal (${_stepsGoal.toInt()} steps)'
                    : 'Connect device to track steps',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: _stepsRatio >= 1.0
                        ? const Color(0xFF166534)
                        : const Color(0xFF1A56DB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INSIGHT CARD ────────────────────────────────────────────────────────────
  Widget _buildInsightCard() {
    String title, body;
    Color iconBg, titleColor;
    IconData icon;

    if (!_bleConnected) {
      title      = 'Connect\nDevice';
      body       = 'Connect your insole to see personalized insights.';
      iconBg     = const Color(0xFF9CA3AF);
      titleColor = const Color(0xFF6B7280);
      icon       = Icons.bluetooth_searching;
    } else if (_fallDet) {
      title      = 'Fall\nDetected!';
      body       = 'A fall was detected. Please check on the patient immediately.';
      iconBg     = const Color(0xFFDC2626);
      titleColor = const Color(0xFFDC2626);
      icon       = Icons.warning_amber_rounded;
    } else if (_tempAlert) {
      title      = 'High Temp\nAlert!';
      body       = 'Temperature is ${_tempC.toStringAsFixed(1)}°C — above safe threshold. Rest and inspect foot.';
      iconBg     = const Color(0xFFFCA5A5);
      titleColor = const Color(0xFF991B1B);
      icon       = Icons.thermostat;
    } else if (!_isSafe) {
      title      = 'Pressure\nWarning';
      body       = 'Sustained pressure detected. Consider repositioning to reduce risk.';
      iconBg     = const Color(0xFFFBBF24);
      titleColor = const Color(0xFF92400E);
      icon       = Icons.compress;
    } else {
      title      = "You're doing\ngreat!";
      body       = 'All sensors within safe range. Keep up the good routine!';
      iconBg     = const Color(0xFF4ADE80);
      titleColor = const Color(0xFF166534);
      icon       = Icons.trending_down;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: titleColor, height: 1.2)),
                const SizedBox(height: 6),
                Text(body, style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF6B7280), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WEEKLY TEMPERATURE CARD ─────────────────────────────────────────────────
  Widget _buildWeeklyTempCard() {
    final temps  = _tempHistory;
    final labels = _tempLabels;
    if (temps.isEmpty) return const SizedBox();

    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final avg  = temps.reduce((a, b) => a + b) / temps.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temperature History', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
          Text('AVG ${avg.toStringAsFixed(1)}°C',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF), letterSpacing: 1)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(temps.length, (i) {
              final ratio = (temps[i] - minT + 0.2) / (maxT - minT + 0.2);
              final isHighest = temps[i] == maxT;
              final isAlert   = temps[i] >= 38.5;
              return Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 32,
                  height: 80 * ratio + 20,
                  decoration: BoxDecoration(
                    color: isAlert
                        ? const Color(0xFFFCA5A5)
                        : isHighest
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(i < labels.length ? labels[i] : '',
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: const Color(0xFF9CA3AF))),
                Text('${temps[i].toStringAsFixed(1)}°',
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500)),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  // ── PRESSURE DISTRIBUTION CARD ──────────────────────────────────────────────
  Widget _buildPressureCard() {
    final total = _totalPressure > 0 ? _totalPressure : 100;

    final zones = [
      _PressureZone('Heel',       _heel      / total, const Color(0xFF1A56DB)),
      _PressureZone('Ball',       _ball      / total, const Color(0xFF6366F1)),
      _PressureZone('Arch',       _arch      / total, const Color(0xFF93C5FD)),
      _PressureZone('Big Toe',    _bigToe    / total, const Color(0xFFA5B4FC)),
      _PressureZone('Second Toe', _secondToe / total, const Color(0xFFBAE6FD)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pressure Distribution', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
          Text('LIVE DATA', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF), letterSpacing: 1)),
          const SizedBox(height: 16),
          ...zones.map((z) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(z.label, style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500)),
                    Text('${(z.value * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: z.color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    child: LinearProgressIndicator(
                      value: z.value.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(z.color),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── ALERT SUMMARY CARD ──────────────────────────────────────────────────────
  Widget _buildAlertSummaryCard() {
    final gaitSymmetry = _latest?.gaitSymmetry ?? 0;
    final gaitAlert    = _latest?.gaitAlert    ?? false;
    final accelG       = _latest?.accelG       ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Summary', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
          const SizedBox(height: 16),

          _summaryRow('Steps',         _stepsStr,                          Icons.directions_walk,  const Color(0xFF1A56DB)),
          _summaryRow('Temperature',   _bleConnected && _tempC > 0 ? '${_tempC.toStringAsFixed(1)}°C' : '--',
                                                                           Icons.thermostat,       _tempAlert ? const Color(0xFFDC2626) : const Color(0xFF166534)),
          _summaryRow('Acceleration',  _bleConnected ? '${accelG.toStringAsFixed(2)}g' : '--',
                                                                           Icons.speed,            const Color(0xFF6366F1)),
          _summaryRow('Gait Symmetry', _bleConnected ? '${gaitSymmetry.toStringAsFixed(1)}%' : '--',
                                                                           Icons.accessibility_new, gaitAlert ? const Color(0xFFF59E0B) : const Color(0xFF166534)),
          _summaryRow('Fall Detected', _bleConnected ? (_fallDet ? 'YES ⚠️' : 'No') : '--',
                                                                           Icons.personal_injury,  _fallDet ? const Color(0xFFDC2626) : const Color(0xFF166534)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: GoogleFonts.poppins(
              fontSize: 14, color: const Color(0xFF374151))),
        ),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _PressureZone {
  final String label;
  final double value;
  final Color  color;
  const _PressureZone(this.label, this.value, this.color);
}