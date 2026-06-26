import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E63D5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Alerts',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E63D5),
                    ),
                  ),
                ],
              ),
            ),

            // ── Subtitle ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Review your recent foot health notifications\nand system status.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Alert List ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: const [
                  // 1 — Heel Pressure High (red, warning)
                  _AlertCard(
                    borderColor: Color(0xFFC0392B),
                    iconBg: Color(0xFFFFE4E4),
                    iconColor: Color(0xFFC0392B),
                    icon: Icons.warning_amber_rounded,
                    title: 'Heel Pressure\nHigh',
                    time: '2 hours\nago',
                    body:
                        'Please rest and check your skin for any signs of redness or irritation.',
                    showButton: true,
                  ),

                  SizedBox(height: 16),

                  // 2 — Temperature Rising (dark red, thermometer)
                  _AlertCard(
                    borderColor: Color(0xFF8B1A1A),
                    iconBg: Color(0xFFFFE4E4),
                    iconColor: Color(0xFF8B1A1A),
                    icon: Icons.thermostat_outlined,
                    title: 'Temperature\nRising',
                    time: 'Today,\n11:30 AM',
                    body:
                        'Minor inflammation detected in left arch. Monitor closely and avoid long walks today.',
                    showButton: true,
                  ),

                  SizedBox(height: 16),

                  // 3 — System Connected (green, check)
                  _AlertCard(
                    borderColor: Color(0xFF22C55E),
                    iconBg: Color(0xFF22C55E),
                    iconColor: Colors.white,
                    icon: Icons.check_circle_outline,
                    title: 'System\nConnected',
                    time: 'Today,\n8:00 AM',
                    body:
                        'Insole sensors are working correctly and synchronized with your device.',
                    showButton: false,
                  ),

                  SizedBox(height: 16),

                  // 4 — Daily Scan Reminder (blue, info)
                  _AlertCard(
                    borderColor: Color(0xFF1E63D5),
                    iconBg: Color(0xFFDCE8FF),
                    iconColor: Color(0xFF1E63D5),
                    icon: Icons.info_outline,
                    title: 'Daily Scan\nReminder',
                    time: 'Yesterday',
                    body:
                        "Don't forget to perform your evening pressure check before bedtime.",
                    showButton: false,
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALERT CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _AlertCard extends StatelessWidget {
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String time;
  final String body;
  final bool showButton;

  const _AlertCard({
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.time,
    required this.body,
    required this.showButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left color bar ──────────────────────────────────────────────
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // ── Card content ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Title + Time row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),

                        // Title
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                        ),

                        // Time
                        Text(
                          time,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Body text
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        height: 1.55,
                      ),
                    ),

                    // Button (optional)
                    if (showButton) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E63D5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            'Check Feet Now',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}