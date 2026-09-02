import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'services/theme_controller.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyFlowApp());
}

class StudyFlowApp extends StatefulWidget {
  const StudyFlowApp({super.key, this.apiClient, this.tokenStorage});

  final ApiClient? apiClient;
  final TokenStorage? tokenStorage;

  @override
  State<StudyFlowApp> createState() => _StudyFlowAppState();
}

class _StudyFlowAppState extends State<StudyFlowApp> {
  late final ApiClient _api;
  late final AppState _appState;
  late final AuthState _auth;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _appState = AppState(apiClient: _api);
    _auth = AuthState(
        apiClient: _api,
        tokenStorage: widget.tokenStorage ?? SecureTokenStorage(),
        appState: _appState);
    _auth.initialize();
  }

  @override
  void dispose() {
    _auth.dispose();
    _appState.dispose();
    if (widget.apiClient == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, child) {
        return AnimatedBuilder(
            animation: Listenable.merge([_auth, _appState]),
            builder: (context, _) => MaterialApp(
                  // Replacing the navigator also dismisses forms from the previous user.
                  key: ValueKey(_auth.currentUser?.id),
                  title: 'StudyFlow',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: currentMode,
                  home: _home(),
                ));
      },
    );
  }

  Widget _home() {
    if (_auth.status == AuthStatus.unauthenticated) {
      return AuthScreen(authState: _auth);
    }
    if (_auth.status == AuthStatus.initializing) {
      return _statusScreen(error: _auth.error, retry: _auth.initialize);
    }
    if (_appState.isLoading ||
        !_appState.hasLoaded ||
        _appState.loadError != null) {
      return _statusScreen(
          error: _appState.loadError,
          retry: _appState.loadData,
          logout: _auth.logout);
    }
    return MainNavigationScreen(appState: _appState, authState: _auth);
  }

  Widget _statusScreen(
          {String? error, required VoidCallback retry, VoidCallback? logout}) =>
      Scaffold(
          body: SafeArea(
              child: Center(
                  child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (error == null) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Carregando...'),
          ] else ...[
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente')),
          ],
          if (logout != null)
            TextButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair')),
        ]),
      ))));
}
