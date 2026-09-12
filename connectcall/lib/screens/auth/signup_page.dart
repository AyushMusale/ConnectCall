import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import '../../widgets/brand_logo.dart';
import 'bloc/auth_bloc.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/signup_form.dart';

/// Main SignUp screen featuring the ConnectCall brand aesthetic,
/// responsive layout adapting via LayoutBuilder and clamp,
/// and BLoC state management for form submission.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLoginTap() {
    try {
      context.read<AuthBloc>().add(const AuthResetState());
    } catch (_) {}
    context.go('/login');
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignUpSubmitted(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
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
                        'Account created successfully! Welcome to ConnectCall.',
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
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage ?? 'Failed to create account.',
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
                  final isWide = constraints.maxWidth >= 780;

                  if (isWide) {
                    return _buildWideLayout(
                      context: context,
                      constraints: constraints,
                      isLoading: isLoading,
                    );
                  }

                  return _buildMobileLayout(
                    context: context,
                    constraints: constraints,
                    isLoading: isLoading,
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

  /// Responsive single-column layout for mobile form factors
  Widget _buildMobileLayout({
    required BuildContext context,
    required BoxConstraints constraints,
    required bool isLoading,
  }) {
    // Dynamic values scaled and clamped for mobile screens
    final horizontalPadding = (constraints.maxWidth * 0.055).clamp(16.0, 24.0);
    final illustrationSize = (constraints.maxWidth * 0.44).clamp(140.0, 210.0);
    final titleFontSize = (constraints.maxWidth * 0.078).clamp(24.0, 32.0);
    final subtitleFontSize = (constraints.maxWidth * 0.036).clamp(13.0, 14.5);
    final cardHorizontalMargin = ((constraints.maxWidth - 520) / 2).clamp(
      0.0,
      32.0,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF9F2), Color(0xFFFFF3E7), Colors.white],
          stops: [0.0, 0.35, 0.65],
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section: Brand Logo, Headline & Illustration
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
                    // ConnectCall logo at the top
                    const BrandLogo(),
                    const SizedBox(height: 18),

                    // Headline + Illustration in a balanced row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Connect\nwith anyone,\n',
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A),
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                    letterSpacing: -0.6,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'anywhere.',
                                      style: TextStyle(
                                        color: const Color(0xFFFF6E00),
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Make real connections\nthrough seamless calls\nand conversations.',
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

              // Bottom section: Rounded White Form Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: cardHorizontalMargin),
                child: SignupForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  isLoading: isLoading,
                  onSubmit: () => _submit(context),
                  onLoginTap: _handleLoginTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Responsive two-column split layout for tablet and desktop viewports
  Widget _buildWideLayout({
    required BuildContext context,
    required BoxConstraints constraints,
    required bool isLoading,
  }) {
    final panelPadding = (constraints.maxWidth * 0.04).clamp(24.0, 56.0);
    final formWidth = (constraints.maxWidth * 0.44).clamp(380.0, 480.0);
    final heroSize = (constraints.maxWidth * 0.22).clamp(220.0, 320.0);

    return Row(
      children: [
        // Left side: Brand, Hero headline, Subtitle & Illustration
        Expanded(
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.all(panelPadding),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF9F2), Color(0xFFFFF3E7)],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(fontSize: 26, iconSize: 40),
                  const SizedBox(height: 48),
                  const AuthHeader(titleFontSize: 44, subtitleFontSize: 16),
                  const SizedBox(height: 36),
                  Center(child: AuthIllustration(size: heroSize)),
                ],
              ),
            ),
          ),
        ),

        // Right side: Centered form card
        Expanded(
          child: Container(
            height: double.infinity,
            color: const Color(0xFFFAFBFD),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: panelPadding,
                vertical: 32,
              ),
              child: Center(
                child: SizedBox(
                  width: formWidth,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SignupForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isLoading: isLoading,
                      onSubmit: () => _submit(context),
                      onLoginTap: _handleLoginTap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
