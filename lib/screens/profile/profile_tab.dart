import 'package:flutter/material.dart';

import '../../services/theme_controller.dart';
import '../../state/auth_state.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.authState});
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil & Configurações')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeModeNotifier,
        builder: (context, themeMode, _) {
          final isDark = themeMode == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  authState.currentUser?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: authState.isBusy ? null : authState.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aparência',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Card(
                child: SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo Escuro'),
                  subtitle: Text(
                    isDark ? 'Tema Escuro ativado' : 'Tema Claro ativado',
                  ),
                  value: isDark,
                  onChanged: (val) => ThemeController.toggleTheme(val),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Integrações',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.key),
                  title: Text('Status da IA'),
                  subtitle: Text('IA externa: integração futura via backend'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
