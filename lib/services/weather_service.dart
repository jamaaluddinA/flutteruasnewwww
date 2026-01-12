import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  // API Key untuk OpenWeatherMap (Gratis - daftar di openweathermap.org)
  static const String _apiKey =
      'YOUR_API_KEY_HERE'; // Ganti dengan API key Anda
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _cacheKey = 'cached_weather';

  static Future<Map<String, dynamic>> getWeatherByCoordinates(
      double lat, double lng, String placeName) async {
    try {
      print('🌤️ Fetching weather for: $lat, $lng');

      // Jika API key masih default, langsung return mock data
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        print('⚠️ Using mock weather data (API key not set)');
        return _getMockWeatherData(placeName);
      }

      final response = await http
          .get(Uri.parse(
              '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=id'))
          .timeout(const Duration(seconds: 10));

      print('🌤️ Weather API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);

        // Save to cache
        await _saveToCache(weatherData);

        return _parseWeatherData(weatherData);
      } else if (response.statusCode == 401) {
        print('⚠️ Invalid API Key, using mock data');
        return _getMockWeatherData(placeName);
      } else {
        print('⚠️ Weather API error, using mock data');
        return _getMockWeatherData(placeName);
      }
    } catch (e) {
      print('❌ Weather API error: $e');

      // Try to load from cache
      final cachedWeather = await _loadFromCache();
      if (cachedWeather.isNotEmpty) {
        print('✅ Using cached weather data');
        return cachedWeather;
      }

      // Return mock data if cache is empty and API fails
      return _getMockWeatherData(placeName);
    }
  }

  static Future<Map<String, dynamic>> getWeatherByCity(String city) async {
    try {
      print('🌤️ Fetching weather for city: $city');

      // Jika API key masih default, langsung return mock data
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        return _getMockWeatherData(city);
      }

      final response = await http
          .get(Uri.parse(
              '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric&lang=id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        await _saveToCache(weatherData);
        return _parseWeatherData(weatherData);
      } else {
        print('⚠️ City not found or API error');
        return _getMockWeatherData(city);
      }
    } catch (e) {
      print('❌ City weather error: $e');
      final cachedWeather = await _loadFromCache();
      if (cachedWeather.isNotEmpty) {
        return cachedWeather;
      }
      return _getMockWeatherData(city);
    }
  }

  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    return {
      'temperature': data['main']['temp'].round(),
      'feels_like': data['main']['feels_like'].round(),
      'humidity': data['main']['humidity'],
      'description': data['weather'][0]['description'],
      'icon': data['weather'][0]['icon'],
      'city': data['name'],
      'country': data['sys']['country'],
      'wind_speed': data['wind']['speed'],
      'pressure': data['main']['pressure'],
      'visibility': data['visibility'] != null
          ? data['visibility'] / 1000
          : 0, // Convert to km
      'sunrise': data['sys']['sunrise'],
      'sunset': data['sys']['sunset'],
      'is_mock': false,
    };
  }

  static Future<void> _saveToCache(Map<String, dynamic> weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(weatherData));
      print('✅ Weather data cached');
    } catch (e) {
      print('❌ Error caching weather: $e');
    }
  }

  static Future<Map<String, dynamic>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final weatherData = json.decode(cachedData);
        return _parseWeatherData(weatherData);
      }
      return {};
    } catch (e) {
      print('❌ Error loading cached weather: $e');
      return {};
    }
  }

  static Future<void> clearWeatherCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('✅ Weather cache cleared');
    } catch (e) {
      print('❌ Error clearing weather cache: $e');
    }
  }

  // ✅ PUBLIC method untuk mock data
  static Map<String, dynamic> getMockWeatherData(String placeName) {
    return _getMockWeatherData(placeName);
  }

  static Map<String, dynamic> _getMockWeatherData(String placeName) {
    // Random weather conditions for variety
    final weatherConditions = [
      {'desc': 'Cerah Berawan', 'temp': 28, 'icon': '04d'},
      {'desc': 'Cerah', 'temp': 30, 'icon': '01d'},
      {'desc': 'Berawan', 'temp': 27, 'icon': '03d'},
      {'desc': 'Hujan Ringan', 'temp': 26, 'icon': '10d'},
      {'desc': 'Gerimis', 'temp': 25, 'icon': '09d'},
    ];

    final index = DateTime.now().second % weatherConditions.length;
    final condition = weatherConditions[index];

    // Extract values dengan tipe yang benar
    final int temp = condition['temp'] as int;
    final String desc = condition['desc'] as String;
    final String icon = condition['icon'] as String;

    return {
      'temperature': temp,
      'feels_like': temp + 2, // Sekarang aman karena temp bertipe int
      'humidity': 70 + DateTime.now().second % 20,
      'description': desc,
      'icon': icon,
      'city': placeName.isNotEmpty ? placeName : 'Jakarta',
      'country': 'ID',
      'wind_speed': 3.5 + (DateTime.now().second % 30) / 10,
      'pressure': 1010 + DateTime.now().second % 10,
      'visibility': 8 + (DateTime.now().second % 4).toDouble(),
      'sunrise': 1649721600,
      'sunset': 1649764800,
      'is_mock': true,
    };
  }

  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static String getWeatherEmoji(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('cerah') || desc.contains('clear')) return '☀️';
    if (desc.contains('awan') || desc.contains('cloud')) return '☁️';
    if (desc.contains('hujan') || desc.contains('rain')) return '🌧️';
    if (desc.contains('petir') || desc.contains('thunder')) return '⛈️';
    if (desc.contains('salju') || desc.contains('snow')) return '❄️';
    if (desc.contains('kabut') || desc.contains('fog')) return '🌫️';
    return '🌤️';
  }

  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
