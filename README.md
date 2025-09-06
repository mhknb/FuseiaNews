# Fuseia News - AI Destekli Haber Akışı Uygulaması

Fuseia News, yapay zeka destekli haber toplama ve özetleme uygulamasıdır. Kullanıcıların ilgi alanlarına göre kişiselleştirilmiş haber akışları sunar.

## Özellikler

- 🤖 AI destekli haber özetleme
- 📱 Kişiselleştirilmiş haber akışları
- 🎯 Kategori bazlı filtreleme
- 📊 Çoklu RSS kaynak desteği
- 🌐 YouTube entegrasyonu
- 📱 Modern ve kullanıcı dostu arayüz

## Kurulum

### Gereksinimler
- Flutter SDK (3.7.2+)
- Dart SDK
- Android Studio / Xcode
- Git

### Adımlar

1. **Repository'yi klonlayın:**
   ```bash
   git clone https://github.com/mhknb/FuseiaNews.git
   cd FuseiaNews
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Environment variables'ları ayarlayın:**
   ```bash
   # .env dosyası oluşturun
   cp .env.example .env
   ```
   
   `.env` dosyasını düzenleyip API anahtarlarınızı ekleyin:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   PEXELS_API_KEY=your_pexels_api_key_here
   ```

4. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## Güvenlik

⚠️ **ÖNEMLİ GÜVENLİK UYARILARI:**

- `.env` dosyasını asla Git'e commit etmeyin
- API anahtarlarınızı güvenli tutun
- `keystore.properties` dosyasını Git'e eklemeyin
- Production ortamında farklı API anahtarları kullanın

## API Anahtarları

Uygulamanın çalışması için aşağıdaki API anahtarlarına ihtiyaç vardır:

- **Gemini AI**: Haber özetleme ve çeviri için
- **Pexels**: Görsel arama için (opsiyonel)

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
