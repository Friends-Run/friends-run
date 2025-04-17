import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/views/auth/auth_main_view.dart';
import 'package:friends_run/views/no_connection/no_connection_view.dart';
import 'core/providers/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friends Run',
      home: const ConnectivityGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConnectivityGate extends ConsumerWidget {
  const ConnectivityGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      data: (status) {
        if (status == ConnectivityResult.none) {
          return const NoConnectionView();
        }
        return const AuthMainView(); // ou outra tela inicial
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const NoConnectionView(),
    );
  }
}