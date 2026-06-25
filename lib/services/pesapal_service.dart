import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PesapalService {
  static final PesapalService instance = PesapalService._init();
  PesapalService._init();

  // CREDENTIALS - SANDBOX (Update for Production)
  final String _consumerKey = 'k0jh9KAXbWkEkq4AUFukHDczpAz4ypW';
  final String _consumerSecret = 'fasDpsXCrrFsmGozd/MEv5QcdzQ=';
  final String _baseUrl = 'https://cybersandbox.pesapal.com/v3';
  
  String? _cachedIpnId;

  /// STEP 1: AUTHENTICATE
  Future<String?> _getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/Auth/RequestToken'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'consumer_key': _consumerKey, 'consumer_secret': _consumerSecret}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// STEP 2: REGISTER/GET IPN ID (Cached for Efficiency)
  Future<String?> _getIpnId(String token) async {
    if (_cachedIpnId != null) return _cachedIpnId;
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/URLRegister/RegisterIPN'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'url': 'https://kagema-school.supabase.co/functions/v1/pesapal-ipn',
          'ipn_notification_type': 'GET'
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _cachedIpnId = jsonDecode(response.body)['ipn_id'];
        return _cachedIpnId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// STEP 3: INITIATE TRANSACTION
  Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String email,
    required String reference,
    required String studentName,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return {'success': false, 'message': 'AUTH_FAILED'};

    final ipnId = await _getIpnId(token);
    if (ipnId == null) return {'success': false, 'message': 'IPN_REGISTRATION_FAILED'};

    // PHONE FORMATTING FOR STK PUSH (Must be 254...)
    String cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');
    String formattedPhone = cleaned;
    if (cleaned.startsWith('0')) formattedPhone = '254${cleaned.substring(1)}';
    else if (!cleaned.startsWith('254')) formattedPhone = '254$cleaned';

    try {
      final body = {
        "id": reference,
        "currency": "KES",
        "amount": amount,
        "description": "Fees Payment: $studentName",
        "callback_url": "https://kagema-school-app.web.app/payment-status",
        "notification_id": ipnId,
        "billing_address": {
          "email_address": email.isEmpty ? "finance@kagema.edu" : email,
          "phone_number": formattedPhone,
          "country_code": "KE",
          "first_name": studentName.split(' ')[0],
          "last_name": studentName.contains(' ') ? studentName.split(' ').last : "Student",
          "line_1": "Kagema School",
          "city": "Nairobi"
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/Transactions/SubmitOrderRequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'redirect_url': data['redirect_url'],
          'order_tracking_id': data['order_tracking_id']
        };
      }
      return {'success': false, 'message': data['message'] ?? 'TRANSACTION_ERROR'};
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_TIMEOUT'};
    }
  }
}
