import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__PKG__/di/di.dart';
import 'package:__PKG__/features/auth/presentation/login/view/login_cubit.dart';
import 'package:__PKG__/features/auth/presentation/login/view/login_states.dart';
import 'package:__PKG__/generated/locale_keys.g.dart';
import 'package:__PKG__/routing/app_router.gr.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginCubit cubit = getIt();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  StreamSubscription<LoginNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = cubit.navigation.listen(_handleNavigation);
  }

  void _handleNavigation(LoginNavigationAction event) {
    switch (event) {
      case NavigateToHome():
        context.router.replaceAll([const HomeRoute()]);
      case ShowLoginError(:final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      cubit.doAction(
        SubmitLoginAction(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_navSub?.cancel());
    unawaited(cubit.close());
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.auth_login_title.tr())),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.auth_email.tr(context: context),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? '' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.auth_password.tr(context: context),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? '' : null,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<LoginCubit, LoginStates>(
                    builder: (context, state) {
                      final isLoading = state.loginResource.isLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                LocaleKeys.auth_login_button.tr(
                                  context: context,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
