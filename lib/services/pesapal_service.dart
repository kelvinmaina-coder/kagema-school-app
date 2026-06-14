import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PesapalService {
  static final PesapalService instance = PesapalService._init();
  PesapalService._init();

  // CREDENTIALS - QUANTUM ENCODED
  final String _consumerKey = 'k0jh9KAXbWkEkq4AUFukHDczpAz4ypW';
  final String _consumerSecret = 'fasDpsXCrrFsmGozd/MEv5QcdzQ=';
  
  // Base URL (Change to https://pay.pesapal.com/v3/ for Production)
  final String _baseUrl = 'https://cybersandbox.pesapal.com/v3';

  /// STEP 1: AUTHENTICATE & GET TOKEN
  Future<String?> _getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/Auth/RequestToken'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'consumer_key': _consumerKey, 'consumer_secret': _consumerSecret}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['token'];
      }
      return null;
    } catch (e) {
      debugPrint("Pesapal Auth Error: $e");
      return null;
    }
  }

  /// STEP 2: REGISTER IPN (Required for V3)
  Future<String?> _getIpnId(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/URLRegister/RegisterIPN'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'url': 'https://kagema-school.supabase.co/functions/v1/pesapal-ipn', // Replace with your webhook
          'ipn_notification_type': 'GET'
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['ipn_id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// STEP 3: SUBMIT ORDER & GET PAYMENT URL
  Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String email,
    required String reference,
    required String studentName,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return {'success': false, 'message': 'Authentication Failed'};

    final ipnId = await _getIpnId(token);
    if (ipnId == null) return {'success': false, 'message': 'IPN Sync Failed'};

    try {
      final body = {
        "id": reference,
        "currency": "KES",
        "amount": amount,
        "description": "School Fees Payment for $studentName",
        "callback_url": "https://kagema-school-app.web.app/payment-success",
        "notification_id": ipnId,
        "billing_address": {
          "email_address": email,
          "phone_number": phoneNumber,
          "country_code": "KE",
          "first_name": studentName,
          "middle_name": "",
          "last_name": "Guardian",
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
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'redirect_url': data['redirect_url'],
          'order_tracking_id': data['order_tracking_id']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Transaction Aborted'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Pulse Lost'};
    }
  }
}
