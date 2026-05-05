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
import 'providers/subscription_provider.dart';
import 'providers/template_provider.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env é opcional em desenvolvimento.
  }

  await StorageService.instance.init();
  LogService.instance.hydrate();
  await AuthService.instance.ensureBootstrap();

  // AdMob — no-op em desktop/web. Em mobile, inicializa o SDK em paralelo
  // com o resto do bootstrap pra não atrasar o `runApp`.
  // ignore: unawaited_futures
  AdService.instance.initialize();

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
        // Assinatura espelha o usuário ativo: ao logar, carrega o snapshot
        // local; ao deslogar, limpa.
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, AuthProvider auth, SubscriptionProvider? previous) {
            final SubscriptionProvider p = previous ?? SubscriptionProvider();
            p.bindUser(auth.currentUser);
            return p;
          },
        ),
        // Templates por conta: ao logar carrega os templates do usuário;
        // ao deslogar, limpa a lista.
        ChangeNotifierProxyProvider<AuthProvider, TemplateProvider>(
          create: (_) => TemplateProvider(),
          update: (_, AuthProvider auth, TemplateProvider? previous) {
            final TemplateProvider p = previous ?? TemplateProvider();
            p.bindCurrentUser(auth.currentUser);
            return p;
          },
        ),
      ],
      child: const EvoluaProApp(),
    ),
  );
}
