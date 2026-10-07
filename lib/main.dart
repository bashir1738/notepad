import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/note_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await NoteStore.open();
  final settings = await AppSettings.open();
  runApp(NotepadApp(store: store, settings: settings));
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({
    super.key,
    required this.store,
    required this.settings,
  });

  final NoteStore store;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NoteStore>.value(value: store),
        ChangeNotifierProvider<AppSettings>.value(value: settings),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Notepad',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            localizationsDelegates: const [
              FlutterQuillLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
