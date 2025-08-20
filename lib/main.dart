import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sayac_okuma_app/pages/login_page.dart';
import 'package:sayac_okuma_app/pages/register_page.dart';

//HomePage ve DashboardPage import edildi
import 'package:sayac_okuma_app/pages/home_page.dart';
import 'package:sayac_okuma_app/pages/dashboard_page.dart';


void main() async {
  // Firebase başlatma işlemi için gerekli
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sayaç Okuma Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      //HomePage açılış sayfası olarak belirlendi
      initialRoute: '/home',

      //Route haritası eklendi
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
