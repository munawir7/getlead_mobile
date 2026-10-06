import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../leads/lead_list_screen.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Colors taken from the reference UI.
  static const Color backgroundColor = Color(0xFFFAF8F4);
  static const Color redColor = Color(0xFFE52529);
  static const Color darkText = Color(0xFF181818);
  static const Color secondaryText = Color(0xFF77736E);
  static const Color fieldBorder = Color(0xFFE6E2DD);
  static const Color placeholderColor = Color(0xFFB8B4AF);

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(authControllerProvider.notifier).login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
          deviceName: 'getlead_flutter',
        );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    if (authState.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LeadListScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Optional: listen and trigger a floating SnackBar on error
    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: redColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 44),

                        // --------------------------------------------------
                        // LOGO + GETLEAD
                        // --------------------------------------------------
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 51,
                              height: 51,
                              decoration: BoxDecoration(
                                color: redColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'g',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Arial',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Getlead',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 81,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: redColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: 61,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2DED8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: 40,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2DED8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 62),

                        // --------------------------------------------------
                        // MAIN HEADING
                        // --------------------------------------------------
                        const Text(
                          'Your leads\nare waiting.',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1.04,
                            letterSpacing: -1.2,
                          ),
                        ),

                        const SizedBox(height: 13),

                        const Text(
                          'Sign in to pick up your follow-ups.',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --------------------------------------------------
                        // EMAIL / PHONE
                        // --------------------------------------------------
                        const Text(
                          'Email or phone',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Removed rigid SizedBox(height: 58) to prevent RenderFlex overflow
                        TextFormField(
                          controller: _identifierController,
                          enabled: !authState.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'name@company.com',
                            hintStyle: const TextStyle(
                              color: placeholderColor,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: fieldBorder,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: fieldBorder,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: redColor,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: Color(0xFFB45309),
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: Color(0xFFB45309),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or phone';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // --------------------------------------------------
                        // PASSWORD
                        // --------------------------------------------------
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Removed rigid SizedBox(height: 58) to prevent RenderFlex overflow
                        TextFormField(
                          controller: _passwordController,
                          enabled: !authState.isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                          onFieldSubmitted: (_) {
                            if (!authState.isLoading) {
                              _login();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              color: placeholderColor,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.only(
                              left: 17,
                              right: 12,
                              top: 18,
                              bottom: 18,
                            ),
                            suffixIcon: TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: darkText,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(
                                _obscurePassword ? 'Show' : 'Hide',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: fieldBorder,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: fieldBorder,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: redColor,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: Color(0xFFB45309),
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: Color(0xFFB45309),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        // --------------------------------------------------
                        // CONVERTED API ERROR (Styled Alert Banner)
                        // --------------------------------------------------
                        if (authState.errorMessage != null &&
                            authState.errorMessage!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: redColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),

                        // --------------------------------------------------
                        // SIGN IN BUTTON
                        // --------------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 62,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: redColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  redColor.withValues(alpha: 0.65),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // --------------------------------------------------
                        // FOOTER
                        // --------------------------------------------------
                        const Center(
                          child: Text(
                            'Stays signed in on this device',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}