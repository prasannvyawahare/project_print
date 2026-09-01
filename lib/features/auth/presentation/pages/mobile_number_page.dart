import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/primary_action_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Mandatory step after a Google sign-in that has no mobile number on file.
/// Pushed as a full screen (not a dialog) so the keyboard never breaks the
/// layout, and shares the [AuthBloc] instance the login screen created.
class MobileNumberPage extends StatefulWidget {
  const MobileNumberPage({super.key});

  @override
  State<MobileNumberPage> createState() => _MobileNumberPageState();
}

class _MobileNumberPageState extends State<MobileNumberPage> {
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _submit(AuthState state) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthManualMobileSubmitted(
        mobile: _mobileController.text.trim(),
        token: state.pendingAuthToken,
      ),
    );
  }

  void _signOut() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.authBackground),
          child: SafeArea(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isSubmitting = state.isLoading;
                final errorMessage = state.status == AuthStatus.failure
                    ? state.errorMessage
                    : '';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.spacing12,
                        AppDimensions.spacing8,
                        AppDimensions.spacing12,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isSubmitting ? null : _signOut,
                          child: Text(AppConstants.notYouSignOut),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing24,
                          vertical: AppDimensions.spacing12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: AppDimensions.spacing92,
                                height: AppDimensions.spacing92,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppGradients.authCircle,
                                ),
                                child: const Icon(
                                  Icons.phone_iphone_rounded,
                                  color: AppColors.white,
                                  size: AppDimensions.icon42,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing30),
                            Text(
                              AppConstants.mobileNumberTitle,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppDimensions.spacing10),
                            Text(
                              AppConstants.mobileNumberSubtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppDimensions.spacing40),
                            Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _mobileController,
                                enabled: !isSubmitting,
                                autofocus: true,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                style: textTheme.titleMedium,
                                decoration: InputDecoration(
                                  hintText: AppConstants.mobileNumberHint,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacing16,
                                    vertical: AppDimensions.spacing16,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE6E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) {
                                    return AppConstants.mobileNumberRequired;
                                  }
                                  if (!RegExp(
                                    r'^[6-9]\d{9}$',
                                  ).hasMatch(trimmed)) {
                                    return AppConstants.mobileNumberInvalid;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(state),
                              ),
                            ),
                            if (errorMessage.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.spacing12),
                              Text(
                                errorMessage,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppDimensions.spacing30),
                            PrimaryActionButton(
                              label: AppConstants.continueLabel,
                              isLoading: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () => _submit(state),
                              height: AppDimensions.spacing56,
                              fontSize: AppDimensions.spacing18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
