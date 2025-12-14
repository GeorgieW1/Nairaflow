import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../services/otp_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _otpSent = false;
  
  // Timer related
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP when screen opens? 
    // Usually better to let user click "Send" first or auto-send if coming from registration.
    // For now, we'll wait for user action or auto-trigger if desired.
    // Let's auto-send if they just landed here to make it seamless.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOTP();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await OTPService.sendOTP();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _otpSent = true;
          _message = '✅ OTP sent to your email';
          _startTimer();
        } else {
          _message = '❌ ${result['error'] ?? 'Failed to send OTP'}';
          // If failed, allow retry immediately
          _canResend = true; 
        }
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 4) {
      setState(() {
        _message = '❌ Please enter 4-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await OTPService.verifyOTP(_otpController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _message = '✅ Email verified successfully!';
        });
        
        // Refresh user profile to update verification status
        await ref.read(authProvider.notifier).refreshUser();

        if (mounted) {
          // Force navigate to Dashboard
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _message = '❌ ${result['error'] ?? 'Verification failed'}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final email = user?.email ?? 'your email';

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Theme.of(context).colorScheme.primary),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.mark_email_unread_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Check your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to\n$email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            if (!_otpSent && !_isLoading)
               CustomButton(
                 text: 'Send Verification Code',
                 onPressed: _sendOTP,
               ),

            if (_otpSent || _isLoading) ...[
              Pinput(
                controller: _otpController,
                length: 4,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) => _verifyOTP(),
              ),
              
              const SizedBox(height: 32),

              CustomButton(
                text: 'Verify Code',
                isLoading: _isLoading,
                onPressed: _verifyOTP,
              ),

              const SizedBox(height: 24),

              if (_canResend)
                TextButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: const Text('Resend Code'),
                )
              else
                Text(
                  'Resend code in ${_start}s',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],

            const SizedBox(height: 24),

            // Message Area
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('✅') ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('✅') ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _message.contains('✅') ? Icons.check_circle : Icons.error_outline,
                      color: _message.contains('✅') ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _message.contains('✅') ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
