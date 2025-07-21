// lib/core/api/python_api_service.dart

import 'dart:typed_data'; // Byte verileri için
import 'package:http/http.dart' as http;

class PythonApiService {
  // Python Flask sunucumuzun yerel adresi.
  // Bu adres, uygulamanın nerede çalıştığına göre değişir:
  // - Android Emülatörü için: 'http://10.0.2.2:5000'
  // - iOS Simülatörü için: 'http://localhost:5000' veya 'http://127.0.0.1:5000'
  // - Gerçek bir telefonda test ediyorsan: Bilgisayarının yerel IP adresi, örn: 'http://192.168.1.10:5000'
  static const String _baseUrl = 'http://10.0.2.2:5000';

  /// Verilen ham görseli ve başlığı, işlenmesi için Python backend'ine yollar.
  /// [rawImageBytes]: İşlenecek olan ham görselin byte verisi.
  /// [title]: Görselin üzerine yazılacak olan başlık.
  /// Başarılı olursa işlenmiş görselin byte verisini, olmazsa null döndürür.
  Future<Uint8List?> processImageWithPython(Uint8List rawImageBytes, String title) async {
    // Python sunucumuzdaki endpoint'in tam adresi
    final url = Uri.parse('$_baseUrl/process-image');

    try {
      print("Python backend'ine istek gönderiliyor: $url");

      // `http.MultipartRequest`, hem dosya (görsel) hem de metin (başlık)
      // verisini aynı anda göndermek için kullanılır.
      var request = http.MultipartRequest('POST', url);

      // Metin verisini 'fields' alanına ekliyoruz.
      // 'title' anahtarı, Python'da `request.form['title']` ile yakaladığımız anahtarla aynı olmalı.
      request.fields['title'] = title;

      // Dosya verisini 'files' alanına ekliyoruz.
      // `http.MultipartFile.fromBytes` metodu, byte verisinden bir dosya oluşturur.
      request.files.add(http.MultipartFile.fromBytes(
        'image', // 'image' anahtarı, Python'da `request.files['image']` ile yakaladığımız anahtarla aynı olmalı.
        rawImageBytes,
        filename: 'image_to_process.png', // Sunucu tarafında dosya adı önemli değil ama belirtmek iyi bir pratiktir.
      ));

      // İsteği gönder ve cevabı (streamedResponse) bekle.
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      // Gelen stream'i tam bir 'http.Response' nesnesine çevir.
      final response = await http.Response.fromStream(streamedResponse);

      // Cevabın başarılı olup olmadığını kontrol et.
      if (response.statusCode == 200) {
        print("İşlenmiş görsel Python'dan başarıyla alındı!");
        // Cevabın gövdesi (bodyBytes), doğrudan işlenmiş resmin byte'larıdır.
        return response.bodyBytes;
      } else {
        // Hata durumunda, sunucudan gelen hata mesajını konsola yazdır.
        print("Python backend hatası oluştu. Durum Kodu: ${response.statusCode}");
        print("Hata Mesajı: ${response.body}");
        return null;
      }
    } catch (e) {
      // Bağlantı hatası, timeout vb. durumlarda bu blok çalışır.
      print("Python backend'e bağlanırken bir hata oluştu: $e");
      return null;
    }
  }
}