import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart';
import 'models/user.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/evolution_provider.dart';
import 'services/auth_service.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env é opcional — usuário pode configurar a chave no app.
  }

  await StorageService.instance.init();
  LogService.instance.hydrate();
  await AuthService.instance.ensureBootstrap();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..hydrate(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider()..hydrate(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EvolutionProvider>(
          create: (_) => EvolutionProvider()..hydrate(),
          update: (_, AuthProvider auth, EvolutionProvider? previous) {
            final EvolutionProvider p = previous ?? (EvolutionProvider()..hydrate());
            final AppUser? u = auth.currentUser;
            p.bindCurrentUser(u);
            return p;
          },
        ),
      ],
      child: const EvoluaProApp(),
    ),
  );
}
