import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class LocationProvider with ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String _address = 'Mendeteksi lokasi...';
  String _placeName = 'Lokasi Anda';
  Map<String, dynamic> _weatherData = {};
  bool _isLoading = false;
  String _error = '';
  bool _isMockData = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get address => _address;
  String get placeName => _placeName;
  Map<String, dynamic> get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isMockData => _isMockData;
  bool get hasData => _latitude != null && _longitude != null;
  bool get hasWeatherData => _weatherData.isNotEmpty;

  Future<void> getCurrentLocation() async {
    try {
      _setLoading(true);
      _error = '';

      print('📍 Starting location fetch...');

      // Get current position dengan fallback
      final locationData = await LocationService.getLocationWithFallback();

      _latitude = locationData['latitude'];
      _longitude = locationData['longitude'];
      _address = locationData['address'];
      _placeName = locationData['place_name'] ?? 'Lokasi Anda';
      _isMockData = locationData['isMock'] ?? false;

      // Get weather data menggunakan place name
      await _getWeatherData();

      print('✅ Location data loaded successfully');
      print('   - Latitude: $_latitude');
      print('   - Longitude: $_longitude');
      print('   - Address: $_address');
      print('   - Place Name: $_placeName');
      print('   - Is Mock: $_isMockData');

      notifyListeners();
    } catch (e) {
      _error = 'Gagal mendapatkan lokasi: $e';
      print('❌ Location error: $_error');

      // Fallback to mock data
      await _useMockData();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getWeatherData() async {
    try {
      if (_latitude != null && _longitude != null) {
        final weather = await WeatherService.getWeatherByCoordinates(
          _latitude!,
          _longitude!,
          _placeName,
        );
        _weatherData = weather;
        _isMockData =
            weather.containsKey('is_mock') && weather['is_mock'] == true;

        // Update place name dari data cuaca jika tersedia
        if (weather.containsKey('city') &&
            weather['city'] != null &&
            weather['city'] != 'Lokasi Anda') {
          _placeName = weather['city'];
        }
      }
    } catch (e) {
      print('❌ Weather data error: $e');
      _weatherData = _getFallbackWeatherData();
      _isMockData = true;
    }
  }

  Map<String, dynamic> _getFallbackWeatherData() {
    return WeatherService.getMockWeatherData(_placeName);
  }

  Future<void> _useMockData() async {
    try {
      print('📍 Using mock location data for development');
      final mockData = LocationService.getMockLocationData();
      _latitude = mockData['latitude'];
      _longitude = mockData['longitude'];
      _address = mockData['address'];
      _placeName = 'Jakarta Pusat';
      _weatherData = _getFallbackWeatherData();
      _isMockData = true;
    } catch (e) {
      print('❌ Mock data error: $e');
    }
  }

  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String getTemperature() {
    return _weatherData.isNotEmpty
        ? '${_weatherData['temperature']}°C'
        : '--°C';
  }

  String getWeatherDescription() {
    return _weatherData.isNotEmpty
        ? '${_weatherData['description']}'
        : 'Tidak tersedia';
  }

  String getWeatherEmoji() {
    return _weatherData.isNotEmpty
        ? WeatherService.getWeatherEmoji(_weatherData['description'])
        : '🌤️';
  }

  String getHumidity() {
    return _weatherData.isNotEmpty && _weatherData['humidity'] != null
        ? '${_weatherData['humidity']}%'
        : '--%';
  }

  String getWindSpeed() {
    if (_weatherData.isNotEmpty && _weatherData['wind_speed'] != null) {
      return '${_weatherData['wind_speed'].toStringAsFixed(1)} m/s';
    }
    return '-- m/s';
  }

  String getPressure() {
    return _weatherData.isNotEmpty && _weatherData['pressure'] != null
        ? '${_weatherData['pressure']} hPa'
        : '-- hPa';
  }

  String getVisibility() {
    if (_weatherData.isNotEmpty && _weatherData['visibility'] != null) {
      return '${_weatherData['visibility'].toStringAsFixed(1)} km';
    }
    return '-- km';
  }

  String getSunrise() {
    if (_weatherData.isNotEmpty && _weatherData['sunrise'] != null) {
      return WeatherService.formatTime(_weatherData['sunrise']);
    }
    return '--:--';
  }

  String getSunset() {
    if (_weatherData.isNotEmpty && _weatherData['sunset'] != null) {
      return WeatherService.formatTime(_weatherData['sunset']);
    }
    return '--:--';
  }

  // Format lokasi untuk ditampilkan dengan lebih rapi
  String getFormattedLocation() {
    if (_address.contains('Lat:')) {
      return _placeName;
    }

    // Ambil bagian pertama dari alamat sebagai nama tempat utama
    final parts = _address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }

    return _placeName;
  }

  // Format alamat lengkap untuk detail view
  String getFullAddress() {
    return _address;
  }

  // Koordinat yang diformat
  String getFormattedCoordinates() {
    if (_latitude != null && _longitude != null) {
      return '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
    }
    return '--, --';
  }
}
