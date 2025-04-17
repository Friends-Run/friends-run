import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Views
import 'package:friends_run/views/auth/auth_main_view.dart';
import 'package:friends_run/views/no_connection/no_connection_view.dart';
import 'package:friends_run/views/home/home_view.dart';

// Providers
import 'package:friends_run/core/providers/connectivity_provider.dart';
import 'package:friends_run/core/providers/auth_provider.dart';

// Firebase configuration
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeFirebase();
  await _initializeAppCheck();

  runApp(const ProviderScope(child: FriendsRunApp()));
}

class FriendsRunApp extends StatelessWidget {
  const FriendsRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friends Run',
      debugShowCheckedModeBanner: false,
      home: const ConnectivityGate(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class ConnectivityGate extends ConsumerWidget {
  const ConnectivityGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityProvider);

    return connectivityStatus.when(
      data: (status) => _buildContentBasedOnConnectivity(ref, status),
      loading: () => _buildLoadingIndicator(),
      error: (error, stack) => const NoConnectionView(),
    );
  }

  Widget _buildContentBasedOnConnectivity(WidgetRef ref, ConnectivityResult status) {
    if (status == ConnectivityResult.none) {
      return const NoConnectionView();
    }

    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      data: (user) => user != null ? const HomeView() : const AuthMainView(),
      loading: () => _buildLoadingIndicator(),
      error: (error, stack) => _buildErrorView(error),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Scaffold(
      body: Center(
        child: Text('Erro: ${error.toString()}'),
      ),
    );
  }
}

// Firebase Initialization Helpers
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Erro na inicialização do Firebase: $e');
    rethrow;
  }
}

Future<void> _initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // Use playIntegrity em produção
      // appleProvider: AppleProvider.appAttest, // Para iOS
    );
    debugPrint('App Check ativado com sucesso');
  } catch (e) {
    debugPrint('Erro ao ativar App Check: $e');
    // Em produção, considere bloquear o app se o App Check falhar
  }
}