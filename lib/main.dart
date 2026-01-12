import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ ADD THIS

import 'pages/login_screen.dart';
import 'pages/home_screen.dart';
import 'pages/profile_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'services/supabase_service.dart'; // ✅ CHANGE THIS

void main() async {
  // ✅ PASTIKAN WIDGETS BINDING DIINISIALISASI DULU
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ JALANKAN APLIKASI
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String _username = "User";
  bool _supabaseConnected = false; // ✅ RENAME THIS

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // ✅ LOAD USER PREFERENCES
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;
      final username = prefs.getString('username') ?? 'User';

      // ✅ INISIALISASI SUPABASE CONNECTION
      print('🔄 Initializing Supabase connection...');
      try {
        await SupabaseService.initialize();
        _supabaseConnected = true; // ✅ RENAME THIS
        print('✅ Supabase backend connected successfully');
      } catch (e) {
        _supabaseConnected = false;
        print('⚠️ Supabase connection failed: $e');
        print('💡 Make sure:');
        print('   1. You have Supabase project created');
        print('   2. Anon key and URL are correct');
        print('   3. Table "products" exists in Supabase');
      }

      setState(() {
        _isLoggedIn = loggedIn;
        _username = username;
        _isInitialized = true;
      });

      print('✅ App initialized successfully');
      print('   - Logged in: $_isLoggedIn');
      print('   - User: $_username');
      print('   - Supabase Connected: $_supabaseConnected'); // ✅ RENAME THIS
    } catch (e) {
      print('❌ App initialization error: $e');
      setState(() {
        _isLoggedIn = false;
        _isInitialized = true;
        _supabaseConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Shopping List App',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: _isLoggedIn
                ? HomePage(
                    username: _username,
                    mysqlConnected:
                        _supabaseConnected, // ✅ UPDATE PARAM NAME LATER
                  )
                : const LoginScreen(),
          );
        },
      ),
    );
  }

  // ✅ LOADING SCREEN (sama, tidak berubah)
  Widget _buildLoadingScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  size: 40,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading Shopping App...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Initializing database connection...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Theme methods (sama, tidak berubah)
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.redAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.redAccent,
        primary: Colors.redAccent,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.redAccent),
        trackColor:
            MaterialStateProperty.all(Colors.redAccent.withOpacity(0.5)),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.redAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.redAccent,
        primary: Colors.redAccent,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.redAccent),
        trackColor:
            MaterialStateProperty.all(Colors.redAccent.withOpacity(0.5)),
      ),
      useMaterial3: true,
    );
  }
}

// ✅ HOMEPAGE WIDGET YANG DIUPDATE
class HomePage extends StatefulWidget {
  final String username;
  final bool mysqlConnected; // ✅ RENAME PARAMETER LATER

  const HomePage({
    super.key,
    required this.username,
    required this.mysqlConnected,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
          mysqlConnected: widget.mysqlConnected), // ✅ UPDATE SCREEN LATER
      ProfileScreen(username: widget.username),
    ];
    print('✅ HomePage initialized for user: ${widget.username}');
    print(
        '   - Supabase Connection: ${widget.mysqlConnected}'); // ✅ RENAME LATER

    // ✅ TAMPILKAN WARNING JIKA SUPABASE TIDAK TERKONEKSI
    if (!widget.mysqlConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConnectionWarning();
      });
    }

    // ✅ TAMPILKAN INFO CACHE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCacheWarning();
    });
  }

  void _showConnectionWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Connection Warning'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supabase database is not connected.'),
            SizedBox(height: 8),
            Text('Please check:'),
            Text('• Internet connection'),
            Text('• Supabase project URL and key'),
            Text('• Table "products" exists in Supabase'),
            SizedBox(height: 8),
            Text('App will use local storage instead.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // _showCacheWarning() dan method lainnya tetap sama...
  void _showCacheWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cached, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cache Feature Enabled'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This app now includes cache functionality:'),
              SizedBox(height: 8),
              Text('• Data is cached when server is unavailable'),
              Text('• Cache indicator shows when using cached data'),
              Text('• You can clear cache from the home screen'),
              SizedBox(height: 8),
              Text(
                'Cache ensures app works offline and improves performance.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got It'),
            ),
          ],
        ),
      );
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
