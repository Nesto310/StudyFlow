import 'package:flutter/material.dart';
import '../../services/theme_controller.dart';
import '../../services/ai_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil & Configurações'),
      ),
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
              const Center(
                child: Text(
                  'Estudante',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Aparência', style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo Escuro'),
                  subtitle: Text(isDark ? 'Tema Escuro ativado' : 'Tema Claro ativado'),
                  value: isDark,
                  onChanged: (val) => ThemeController.toggleTheme(val),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Integrações', style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Status da API de IA'),
                  subtitle: Text(
                    AiService.apiKey == 'SUA_API_KEY_AQUI'
                        ? 'Chave Padrão (Modo Demonstração)'
                        : 'Chave Customizada Configurada',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}