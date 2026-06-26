import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showSnack('Passwords do not match');
      return;
    }
    // TODO: real sign-up logic
    Navigator.pop(context); // go back to login after success
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF1E63D5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 44),

              // ── Medical Kit Icon ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E63D5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: _MedKitIcon()),
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────────────
              Center(
                child: Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Center(
                child: Text(
                  'Monitor your foot health',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Full Name ─────────────────────────────────────────────────
              _label('Full Name'),
              const SizedBox(height: 8),
              _inputField(
                hint: 'Khaled Adel',
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // ── Email Address ─────────────────────────────────────────────
              _label('Email Address'),
              const SizedBox(height: 8),
              _inputField(
                hint: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // ── Phone Number ──────────────────────────────────────────────
              _label('Phone Number'),
              const SizedBox(height: 8),
              _inputField(
                hint: '010000000',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────────────────
              _label('Password'),
              const SizedBox(height: 8),
              _passwordField(
                controller: _passwordController,
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 20),

              // ── Confirm Password ──────────────────────────────────────────
              _label('Confirm Password'),
              const SizedBox(height: 8),
              _passwordField(
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 36),

              // ── Sign Up Button ────────────────────────────────────────────
              GestureDetector(
                onTap: _onSignUp,
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E63D5), Color(0xFF174EA6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E63D5).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Already have account ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Log In',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E63D5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
      );

  // ── Generic Input ──────────────────────────────────────────────────────────
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: 14, color: const Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  // ── Password Input ─────────────────────────────────────────────────────────
  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: GoogleFonts.poppins(
              fontSize: 18, color: const Color(0xFF9CA3AF),
              letterSpacing: 2),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MEDICAL KIT ICON  (drawn with CustomPainter — no asset needed)
// ═══════════════════════════════════════════════════════════════════════════════

class _MedKitIcon extends StatelessWidget {
  const _MedKitIcon();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(46, 46),
        painter: _MedKitPainter(),
      );
}

class _MedKitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final plusPaint = Paint()
      ..color = const Color(0xFF1E63D5)
      ..style = PaintingStyle.fill;

    // ── Bag body ─────────────────────────────────────────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.28, w * 0.92, h * 0.62),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(bodyRect, bgPaint);

    // ── Handle ────────────────────────────────────────────────────────────────
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(w * 0.33, h * 0.28)
      ..lineTo(w * 0.33, h * 0.18)
      ..arcToPoint(
        Offset(w * 0.67, h * 0.18),
        radius: Radius.circular(w * 0.17),
        clockwise: false,
      )
      ..lineTo(w * 0.67, h * 0.28);

    canvas.drawPath(handlePath, handlePaint);

    // ── Plus cross ────────────────────────────────────────────────────────────
    final pw = w * 0.13;
    final ph = h * 0.30;
    final cx = w * 0.50;
    final cy = h * 0.59;

    // vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: pw, height: ph),
        Radius.circular(pw * 0.4),
      ),
      plusPaint,
    );

    // horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: ph, height: pw),
        Radius.circular(pw * 0.4),
      ),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}