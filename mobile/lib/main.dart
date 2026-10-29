import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty || url.contains('YOUR_PROJECT')) {
    runApp(const SetupApp());
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  runApp(const InfoShareApp());
}

class SetupApp extends StatelessWidget {
  const SetupApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '资料库',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C8A)), useMaterial3: true),
    home: Scaffold(
      appBar: AppBar(title: const Text('资料共享 App')),
      body: const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('请先配置 mobile/.env：\\nSUPABASE_URL 和 SUPABASE_ANON_KEY\\n\\n然后重新启动应用。', textAlign: TextAlign.center),
      )),
    ),
  );
}

class InfoShareApp extends StatelessWidget {
  const InfoShareApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '资料库',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C8A), brightness: Brightness.light),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F7FA), elevation: 0),
    ),
    home: const LibraryScreen(),
  );
}
