import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/navigation_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/inventory_provider.dart';
import 'data/services/api_service.dart';
import 'ui/screens/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (context) =>
              AuthProvider(Provider.of<ApiService>(context, listen: false))
                ..checkStatus(),
          update: (context, api, previous) => previous ?? AuthProvider(api),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProxyProvider<ApiService, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, api, previous) =>
              previous ?? NotificationProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, InventoryProvider>(
          create: (context) => InventoryProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, api, previous) =>
              previous ?? InventoryProvider(api),
        ),
      ],
      child: MaterialApp(
        title: 'StockMaster Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF0D9488),
          scaffoldBackgroundColor: const Color(
            0xFFF8FAFC,
          ), // Web App: --bg-main
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D9488),
            primary: const Color(0xFF0D9488),
            surface: Colors.white,
            onSurface: const Color(0xFF0F172A), // Slate 900
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Plus Jakarta Sans', // Mirror web app font
          splashFactory:
              NoSplash.splashFactory, // Remove clicking styles as requested
          highlightColor: Colors.transparent,
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            space: 1,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
            titleTextStyle: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isCheckingAuth) {
              return const LoadingSplash();
            }
            return auth.isAuthenticated
                ? const MainShell()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}

class LoadingSplash extends StatefulWidget {
  const LoadingSplash({super.key});

  @override
  State<LoadingSplash> createState() => _LoadingSplashState();
}

class _LoadingSplashState extends State<LoadingSplash> {
  int _progress = 0;
  String _message = "Initialisation...";

  final List<String> _messages = [
    "Vérification de la session...",
    "Chargement des modules...",
    "Connexion sécurisée...",
    "Synchronisation du stock...",
    "Presque prêt...",
  ];

  @override
  void initState() {
    super.initState();
    _progress = 5; // Start immediately
    print("DEBUG: LoadingSplash initialisé");
    _startLoadingSimulation();
  }

  void _startLoadingSimulation() {
    // Simulate progress for better UX
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 480));
      if (!mounted) return false;

      setState(() {
        if (_progress < 100) {
          _progress += 5;
          _message =
              _messages[(_progress / 21).toInt().clamp(
                0,
                _messages.length - 1,
              )];
        }
      });
      return _progress < 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LOGO
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 80,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 40),
            // TITRE
            const Text(
              "STOCKMASTER",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            // BARRE ET POURCENTAGE
            Container(
              width: 250,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Chargement : $_progress%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // MESSAGE
            Text(
              _message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(username, password);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiants incorrects")),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Mode
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 80,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "STOCKMASTER",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "Gestion de Stock Mobile",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 48),
              _buildTextField(
                _usernameController,
                "Nom d'utilisateur",
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _passwordController,
                "Mot de passe",
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SE CONNECTER",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: const Color(0xFF0F172A).withOpacity(0.4),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.4)),
      ),
    );
  }
}
