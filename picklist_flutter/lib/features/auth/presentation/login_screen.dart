import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_button.dart';
import '../state/auth_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'widgets/pin_input_field.dart';

/// Modern login screen with improved UX
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAuth();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _initializeAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.authenticate(_pinController.text);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: AppSpacing.paddingXL,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusXL,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(),
          AppSpacing.verticalSpaceXL,
          _buildTitle(),
          AppSpacing.verticalSpaceLG,
          _buildPinInput(),
          AppSpacing.verticalSpaceLG,
          _buildLoginButton(),
          AppSpacing.verticalSpaceMD,
          _buildHelpText(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusXL,
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Picklist',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalSpaceSM,
        Text(
          'Enter your PIN to continue',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPinInput() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return PinInputField(
          controller: _pinController,
          onSubmitted: (_) => _authenticate(),
          onChanged: (_) => authProvider.clearError(),
          errorText: authProvider.errorMessage.isNotEmpty
              ? authProvider.errorMessage
              : null,
          enabled: !authProvider.isLoading,
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return CustomButton(
          text: 'Login',
          onPressed: _authenticate,
          isLoading: authProvider.isLoading,
          fullWidth: true,
          icon: Icons.login,
        );
      },
    );
  }

  Widget _buildHelpText() {
    return Text(
      'Default PIN: 1234',
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiary,
      ),
    );
  }
}
