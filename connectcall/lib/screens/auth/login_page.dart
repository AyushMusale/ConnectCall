import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common_button.dart';
import 'bloc/auth_bloc.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/auth_text_field.dart';

/// Companion Login screen matching Login_page.png design,
/// allowing seamless routing between SignUp and Login.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<AuthBloc>().add(const AuthResetState());
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome back to ConnectCall!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.pushNamed('home');
          } else if (state.status == AuthStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage ?? 'Failed to log in.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.submitting;

          return Scaffold(
            backgroundColor: const Color(0xFFFFFDF9),
            body: SafeArea(
              top: true,
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      (constraints.maxWidth * 0.055).clamp(16.0, 24.0);
                  final illustrationSize =
                      (constraints.maxWidth * 0.44).clamp(140.0, 210.0);
                  final titleFontSize =
                      (constraints.maxWidth * 0.078).clamp(24.0, 32.0);
                  final subtitleFontSize =
                      (constraints.maxWidth * 0.036).clamp(13.0, 14.5);
                  final cardHorizontalMargin =
                      ((constraints.maxWidth - 520) / 2).clamp(0.0, 32.0);

                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF9F2),
                          Color(0xFFFFF3E7),
                          Colors.white,
                        ],
                        stops: [0.0, 0.35, 0.65],
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header Section
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                18,
                                horizontalPadding,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const BrandLogo(),
                                  const SizedBox(height: 18),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                text: 'Connect\nwith anyone,\n',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF0F172A),
                                                  fontSize: titleFontSize,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.12,
                                                  letterSpacing: -0.6,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'anywhere.',
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFFFF6E00),
                                                      fontSize: titleFontSize,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -0.6,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Meaningful conversations\nare just a login away.',
                                              style: TextStyle(
                                                color: const Color(0xFF64748B),
                                                fontSize: subtitleFontSize,
                                                height: 1.4,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AuthIllustration(size: illustrationSize),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Form Sheet
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: cardHorizontalMargin,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(32),
                                    topRight: Radius.circular(32),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 24,
                                      offset: const Offset(0, -6),
                                    ),
                                  ],
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(24, 14, 24, 32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 44,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Login to continue to ConnectCall.',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 22),

                                      // Email Field
                                      AuthTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        hint: 'you@example.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.mail_outline_rounded,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Password Field
                                      AuthTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        hint: 'Enter your password',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        textInputAction: TextInputAction.done,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: const Color(0xFF64748B),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),

                                      // Align(
                                      //   alignment: Alignment.centerRight,
                                      //   child: TextButton(
                                      //     onPressed: () {},
                                      //     child: const Text(
                                      //       'Forgot Password?',
                                      //       style: TextStyle(
                                      //         color: Color(0xFFFF6E00),
                                      //         fontSize: 13,
                                      //         fontWeight: FontWeight.w600,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                      const SizedBox(height: 12),

                                      // Submit Button
                                      CommonButton(
                                        label: 'Login',
                                        isLoading: isLoading,
                                        onPressed: isLoading
                                            ? null
                                            : () => _submit(context),
                                      ),
                                      const SizedBox(height: 20),

                                      // Footer: Don't have an account? Sign Up
                                      Center(
                                        child: InkWell(
                                          onTap: () {
                                            try {
                                              context.read<AuthBloc>().add(const AuthResetState());
                                            } catch (_) {}
                                            context.go('/signup');
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            child: Text.rich(
                                              TextSpan(
                                                text:
                                                    "Don't have an account? ",
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                children: const [
                                                  TextSpan(
                                                    text: 'Sign Up',
                                                    style: TextStyle(
                                                      color: Color(0xFFFF6E00),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

    try {
      context.read<AuthBloc>();
      return content;
    } catch (_) {
      return BlocProvider(
        create: (_) => getIt<AuthBloc>(),
        child: content,
      );
    }
  }
}
