import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_stock_analyzer/data/auth_cubit.dart';
import 'package:ai_stock_analyzer/l10n/app_strings.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

/// Shows auth dialog. Returns `true` on successful login/registration.
Future<bool> showAuthDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => BlocProvider.value(
      value: context.read<AuthCubit>(),
      child: const _AuthDialog(),
    ),
  );
  return result ?? false;
}

String _translateAuthError(String? key, AppStrings s) {
  if (key == null) return s.errorGeneric;
  switch (key) {
    case AuthErrorKey.accountNotFound:
      return s.accountNotFound;
    case AuthErrorKey.wrongPassword:
      return s.wrongPassword;
    case AuthErrorKey.emailTaken:
      return s.emailTaken;
    default:
      return s.errorGeneric;
  }
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog();

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    final cubit = context.read<AuthCubit>();
    if (_isLogin) {
      cubit.login(email, password);
    } else {
      cubit.register(email, password);
    }
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.isAuthenticated,
      listener: (context, state) {
        Navigator.of(context).pop(true);
      },
      child: Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: c.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: c.border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Title
                        Text(
                          _isLogin ? s.login : s.register,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? s.enterEmailAndPassword
                              : s.createAccount,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.textPrimary,
                          ),
                          decoration: _inputDecoration(c, hintText: s.emailHint),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.textPrimary,
                          ),
                          decoration: _inputDecoration(c, hintText: s.passwordHint),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),

                        // Error
                        if (state.status == AuthStatus.error &&
                            state.errorKey != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: c.red.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 18, color: c.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _translateAuthError(state.errorKey, s),
                                    style: TextStyle(
                                        fontSize: 14, color: c.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: state.isLoading ? null : _submit,
                            child: state.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: c.isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? s.loginButton
                                        : s.registerButton,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? s.noAccount
                                  : s.haveAccount,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _toggleMode,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  _isLogin ? s.registerButton : s.loginButton,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(AppColors c, {required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 15,
        color: c.textSecondary.withOpacity(0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
