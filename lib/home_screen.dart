import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'alerts_screen.dart';
import 'trends_screen.dart';
import 'profile_screen.dart';
import 'scans_screen.dart';
import 'services/ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SmartInsoleApp());
}

class SmartInsoleApp extends StatelessWidget {
  const SmartInsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Insole',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          primary: const Color(0xFF1A56DB),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNav  = 1;
  int _selectedFoot = 0;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  // ── BLE ──────────────────────────────────────────────────────────────────
  final BleService _ble        = BleService();
  bool             _bleConnected = false;
  String           _bleStatus    = 'Disconnected';

  // ── Live InsoleData from ESP32 ────────────────────────────────────────────
  InsoleData? _data;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _temperature  => _data?.tempString       ?? '--';
  String get _pressure     => _data?.pressureStatusText ?? '--';
  String get _steps        => _data?.stepsString      ?? '--';
  bool   get _isSafe       => _data?.isSafe           ?? true;
  bool   get _hasAlert     => _data?.pressureAlert == true ||
                              _data?.tempAlert    == true ||
                              _data?.fallDetected == true;
  String get _alertMsg     => _data?.statusSub ?? '';
  String get _statusText   => _data?.statusText ?? (_bleConnected ? 'Safe' : 'Connecting...');
  String get _statusSub    => _data?.statusSub  ?? (_bleConnected ? 'Your foot condition is stable' : _bleStatus);

  List<double> get _activityBars {
    if (_data == null) return [0.45, 0.55, 0.65, 0.80, 0.90, 0.75, 0.70];
    return [
      (_data!.heel      / 100).clamp(0.05, 1.0),
      (_data!.ball      / 100).clamp(0.05, 1.0),
      (_data!.arch      / 100).clamp(0.05, 1.0),
      (_data!.bigToe    / 100).clamp(0.05, 1.0),
      (_data!.secondToe / 100).clamp(0.05, 1.0),
      (_data!.heel      / 100).clamp(0.05, 1.0),
      (_data!.ball      / 100).clamp(0.05, 1.0),
    ];
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    // استمع لحالة الاتصال
    _ble.statusStream.listen((status) {
      if (mounted) setState(() => _bleStatus = status);
    });

    // استمع للبيانات الحقيقية من ESP32
    _ble.dataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _bleConnected = true;
        _data = data;
      });
    });

    _connectBLE();
  }

  Future<void> _connectBLE() async {
    setState(() => _bleStatus = 'Scanning...');
    final ok = await _ble.connect();
    if (mounted) setState(() => _bleConnected = ok);
  }

  @override
  void dispose() {
    _animController.dispose();
    _ble.dispose();
    super.dispose();
  }

  void _switchFoot(int index) {
    if (index == _selectedFoot) return;
    _animController.reverse().then((_) {
      setState(() => _selectedFoot = index);
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildFootToggle(),
                      const SizedBox(height: 20),
                      _buildMetricCards(),
                      const SizedBox(height: 20),
                      _buildScanButton(),
                      const SizedBox(height: 20),
                      if (_hasAlert) _buildBatteryAlert(),
                      if (_hasAlert) const SizedBox(height: 20),
                      _buildDailyActivity(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A56DB), width: 2),
              color: const Color(0xFFE8EDFF),
            ),
            child: const Icon(Icons.person, color: Color(0xFF1A56DB), size: 26),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: 'Hello, ', style: TextStyle(color: Color(0xFF1A56DB), fontSize: 18, fontWeight: FontWeight.w700)),
                    TextSpan(text: 'Khaled', style: TextStyle(color: Color(0xFF1A56DB), fontSize: 18, fontWeight: FontWeight.w700)),
                  ]),
                ),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bleConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _bleConnected ? 'Connected' : _bleStatus,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const Spacer(),
          if (!_bleConnected)
            GestureDetector(
              onTap: _connectBLE,
              child: const Padding(padding: EdgeInsets.all(8),
                  child: Icon(Icons.refresh, color: Color(0xFF1A56DB), size: 24)),
            ),
          const Padding(padding: EdgeInsets.all(8),
              child: Icon(Icons.sensors, color: Color(0xFF1A56DB), size: 24)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertsScreen())),
            child: const Padding(padding: EdgeInsets.all(8),
                child: Icon(Icons.notifications_outlined, color: Color(0xFF1A56DB), size: 24)),
          ),
        ],
      ),
    );
  }

  // ── STATUS CARD ───────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    final bgColor   = _isSafe ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5);
    final textColor = _isSafe ? const Color(0xFF166534) : const Color(0xFF991B1B);
    final icon      = _isSafe ? Icons.check_circle_outline : Icons.warning_amber_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          child: Icon(icon, color: textColor, size: 44),
        ),
        const SizedBox(height: 16),
        Text(_statusText, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(_statusSub, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)), textAlign: TextAlign.center),
      ]),
    );
  }

  // ── FOOT TOGGLE ───────────────────────────────────────────────────────────
  Widget _buildFootToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(30)),
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
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 1))] : [],
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: isSelected ? const Color(0xFF1A56DB) : const Color(0xFF6B7280),
        )),
      ),
    );
  }

  // ── METRIC CARDS ──────────────────────────────────────────────────────────
  Widget _buildMetricCards() {
    return Row(children: [
      Expanded(child: _metricCard(icon: Icons.thermostat_outlined, label: 'Temperature', value: _temperature)),
      const SizedBox(width: 16),
      Expanded(child: _metricCard(icon: Icons.speed_outlined, label: 'Pressure', value: _pressure)),
    ]);
  }

  Widget _metricCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF1A56DB), size: 24),
        ),
        const SizedBox(height: 16),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      ]),
    );
  }

  // ── SCAN BUTTON ───────────────────────────────────────────────────────────
  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ScansScreen(
              dataStream: _ble.dataStream,
              isConnected: _bleConnected,
            ))),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.qr_code_scanner, size: 20),
          SizedBox(width: 10),
          Text('Start New Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── ALERT BANNER ──────────────────────────────────────────────────────────
  Widget _buildBatteryAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFFFE4E4), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(_alertMsg,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)))),
      ]),
    );
  }

  // ── DAILY ACTIVITY ────────────────────────────────────────────────────────
  Widget _buildDailyActivity() {
    final bars        = _activityBars;
    const barColor    = Color(0xFF93C5FD);
    const barHighlight = Color(0xFF1A56DB);
    final maxBar      = bars.reduce((a, b) => a > b ? a : b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Daily Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      const SizedBox(height: 12),
      Container(
        height: 160, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(20)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_steps, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1A56DB), letterSpacing: -1)),
            const Text('Steps', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars.length, (i) {
              final isHighest = bars[i] == maxBar;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: 18, height: bars[i] * 100,
                  decoration: BoxDecoration(
                    color: isHighest ? barHighlight : barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ]),
      ),
    ]);
  }

  // ── BOTTOM NAVIGATION ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.person_outline,           activeIcon: Icons.person,           label: 'PROFILE'),
      _NavItem(icon: Icons.home_outlined,            activeIcon: Icons.home,             label: 'HOME'),
      _NavItem(icon: Icons.document_scanner_outlined, activeIcon: Icons.document_scanner, label: 'SCANS'),
      _NavItem(icon: Icons.trending_up_outlined,     activeIcon: Icons.trending_up,      label: 'Trends'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).padding.bottom + 12, left: 8, right: 8),
      child: Row(
        children: List.generate(items.length, (i) {
          final item     = items[i];
          final isActive = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) { Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); return; }
                if (i == 2) { Navigator.push(context, MaterialPageRoute(builder: (_) => ScansScreen(dataStream: _ble.dataStream, isConnected: _bleConnected)));  return; }
                if (i == 3) { Navigator.push(context, MaterialPageRoute(builder: (_) => TrendsScreen(dataStream: _ble.dataStream, isConnected: _bleConnected))); return; }
                setState(() => _selectedNav = i);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(isActive ? item.activeIcon : item.icon,
                    color: isActive ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF), size: 24),
                const SizedBox(height: 4),
                Text(item.label, style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                )),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 6 : 0, height: isActive ? 6 : 0,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A56DB)),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String   label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}