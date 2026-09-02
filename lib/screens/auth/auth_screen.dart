import 'package:flutter/material.dart';

import '../../state/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authState});
  final AuthState authState;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.authState.isBusy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_register) {
      await widget.authState.register(_email.text, _password.text);
    } else {
      await widget.authState.login(_email.text, _password.text);
    }
    if (mounted && widget.authState.status == AuthStatus.authenticated) {
      _password.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.authState,
        builder: (context, _) {
          final auth = widget.authState;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Text('StudyFlow',
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 28),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                  value: false, label: Text('Entrar')),
                              ButtonSegment(
                                  value: true, label: Text('Criar conta')),
                            ],
                            selected: {_register},
                            onSelectionChanged: auth.isBusy
                                ? null
                                : (value) {
                                    setState(() {
                                      _register = value.single;
                                    });
                                    _formKey.currentState!.reset();
                                    _password.clear();
                                    _confirmation.clear();
                                    auth.clearError();
                                  },
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            enabled: !auth.isBusy,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder()),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Informe seu email.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !auth.isBusy,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: _register
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_register) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: auth.isBusy
                                    ? null
                                    : () =>
                                        setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => value == null ||
                                    value.length < 8 ||
                                    value.length > 128
                                ? 'Use entre 8 e 128 caracteres.'
                                : null,
                          ),
                          if (_register) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmation,
                              enabled: !auth.isBusy,
                              obscureText: _obscure,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                  labelText: 'Confirmar senha',
                                  border: OutlineInputBorder()),
                              validator: (value) => value != _password.text
                                  ? 'As senhas devem ser iguais.'
                                  : null,
                            ),
                          ],
                          if (auth.error != null) ...[
                            const SizedBox(height: 16),
                            Text(auth.error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: auth.isBusy ? null : _submit,
                            icon: auth.isBusy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(_register
                                    ? Icons.person_add_outlined
                                    : Icons.login),
                            label: Text(_register ? 'Criar conta' : 'Entrar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
