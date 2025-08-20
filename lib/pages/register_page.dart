import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Kayıt ekranı: form alanları olduğu için StatefulWidget
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //form alanlarını yönetmek için controller lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //hata mesajını UI da göstermek için değişken
  String? _errorMessage;

  //kullanıcı oluşturma akışı
  Future<void> _registerUser() async {
    try {
      //e posta ve şifre ile yeni kullanıcı oluşturma
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //ekran iskeleti
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Açık gri arka plan
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
        backgroundColor: const Color.fromARGB(255, 251, 116, 70), 
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.app_registration, size: 48, color: Color.fromARGB(255, 251, 116, 70)),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _registerUser,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Kayıt Ol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 251, 116, 70),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
