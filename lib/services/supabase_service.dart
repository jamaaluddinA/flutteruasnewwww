import 'dart:convert';
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _cacheKey = 'cached_products';
  static const String _lastRefreshKey = 'last_refresh_timestamp';
  static bool _useCache = false;

  static SupabaseClient? _client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://jrvllyovqsudqbxnrsha.supabase.co',
        anonKey: 'sb_publishable_bI0eJa8hdDaJ3M1YSmUDfQ_HLBKtYnX',
      );
      _client = Supabase.instance.client;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization error: $e');
      throw e;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Get all products with cache support
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      print('📦 Supabase Response: ${response.length} products');

      final List<Product> products = [];
      for (var item in response) {
        try {
          print('🔧 Parsing product: $item');
          final product = Product.fromJson(item);
          products.add(product);
        } catch (e) {
          print('❌ Error parsing product: $item - $e');
        }
      }

      // Save to cache
      await _saveToCache(products);
      _useCache = false;

      print('✅ Successfully parsed ${products.length} products from Supabase');
      return products;
    } catch (e) {
      print('❌ Error getting products from Supabase, trying cache...: $e');

      // Try to load from cache
      final cachedProducts = await _loadFromCache();
      if (cachedProducts.isNotEmpty) {
        _useCache = true;
        print('✅ Loaded ${cachedProducts.length} products from cache');
        return cachedProducts;
      }

      throw e;
    }
  }

  // Load products from cache
  static Future<List<Product>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading from cache: $e');
      return [];
    }
  }

  // Save products to cache
  static Future<void> _saveToCache(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((product) => product.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setString(_lastRefreshKey, DateTime.now().toIso8601String());
      print('✅ Products saved to cache');
    } catch (e) {
      print('❌ Error saving to cache: $e');
    }
  }

  // Get last refresh timestamp
  static Future<DateTime?> getLastRefreshTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastRefreshKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('❌ Error getting last refresh time: $e');
      return null;
    }
  }

  // Check if currently using cache
  static bool isUsingCache() {
    return _useCache;
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastRefreshKey);
      _useCache = false;
      print('✅ Cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing cache: $e');
      throw e;
    }
  }

  // Get product by ID
  static Future<Product?> getProductById(int id) async {
    try {
      final response =
          await client.from('products').select().eq('id', id).single();
      return Product.fromJson(response);
    } catch (e) {
      print('❌ Error getting product by ID: $e');
      return null;
    }
  }

  // Insert product
  static Future<int> insertProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      await clearCache();
      return _parseInt(response['id']);
    } catch (e) {
      print('❌ Error inserting product: $e');
      throw e;
    }
  }

  // Update product
  static Future<bool> updateProduct(Product product) async {
    try {
      await client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id!);

      await clearCache();
      return true;
    } catch (e) {
      print('❌ Error updating product: $e');
      throw e;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(int id) async {
    try {
      await client.from('products').delete().eq('id', id);

      await clearCache();
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      throw e;
    }
  }

  // Check if service is available
  static Future<bool> checkConnection() async {
    try {
      await client.from('products').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Debug method
  static Future<void> debugProducts() async {
    try {
      final response = await client.from('products').select();
      print('🔍 DEBUG Supabase Response:');
      print('🔍 Full response: $response');
      print('🔍 Data type: ${response.runtimeType}');

      if (response is List && response.isNotEmpty) {
        print('🔍 First item: ${response.first}');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
