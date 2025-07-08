// lib/screens/api_key_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'interest_selection_screen.dart';



// Class isimleri genellikle UpperCamelCase ile başlar.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('user_api_key');
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  // SADECE BU FONKSİYON GÜNCELLENDİ
  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_api_key', _apiKeyController.text);

        // Kullanıcıya başarı mesajını göstermeye devam edelim.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Anahtarı başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );


        if (mounted) { // Widget'ın hala ekranda olduğundan emin ol
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const InterestSelectionScreen(),
            ),
          );
        }

      } catch (e) {
        // Hata durumunda sadece hata mesajını göster, yönlendirme yapma.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {


        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Anahtarı Ayarları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini API Anahtarınız',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                obscureText: true, // Anahtarın gizli görünmesi için
                decoration: const InputDecoration(
                  hintText: 'API anahtarınızı buraya yapıştırın',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir API anahtarı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Kaydet butonu
              SizedBox(
                width: double.infinity, // Butonun tüm genişliği kaplaması için
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // _isLoading true ise butonu devre dışı bırak ve animasyon göster
                  onPressed: _isLoading ? null : _saveApiKey,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}