import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class MpesaService {
  static final MpesaService instance = MpesaService._init();
  MpesaService._init();

  // --- Safaricom Daraja API Credentials ---
  // PRO TIP: In a real app, store these in secure environment variables or fetch from your backend.
  // These are standard sandbox credentials for testing.
  String consumerKey = 'zAnZGr88GvAXGvG8GvGvGvGvGvGvGvG8'; // Placeholder - user should replace with their app's key
  String consumerSecret = 'vGvGvGvGvGvGvGvG'; // Placeholder
  
  final String _shortCode = '174379'; // Business Short Code (Sandbox)
  final String _passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  final String _callbackUrl = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'; // Using Safaricom's echo callback for test

  Future<String?> _getAccessToken() async {
    try {
      final auth = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
      final response = await http.get(
        Uri.parse('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': 'Basic $auth'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        debugPrint('Mpesa Auth Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Mpesa Auth Exception: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String reference,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      return {
        'success': false, 
        'message': 'API Authentication Error. Please check your Consumer Key/Secret.'
      };
    }

    // Strict formatting for Safaricom: 2547XXXXXXXX
    String formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '').trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254${formattedPhone.substring(1)}';
    } else if (formattedPhone.length == 9) {
      formattedPhone = '254$formattedPhone';
    }

    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final password = base64Encode(utf8.encode('$_shortCode$_passkey$timestamp'));

    final body = {
      "BusinessShortCode": _shortCode,
      "Password": password,
      "Timestamp": timestamp,
      "TransactionType": "CustomerPayBillOnline",
      "Amount": amount.toInt(),
      "PartyA": formattedPhone,
      "PartyB": _shortCode,
      "PhoneNumber": formattedPhone,
      "CallBackURL": _callbackUrl,
      "AccountReference": "KAGEMA-SCHOOL",
      "TransactionDesc": reference
    };

    try {
      final response = await http.post(
        Uri.parse('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      debugPrint('Mpesa Response: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['ResponseCode'] == '0') {
          return {
            'success': true,
            'CheckoutRequestID': data['CheckoutRequestID'],
            'MerchantRequestID': data['MerchantRequestID'],
            'message': data['CustomerMessage'] ?? 'STK Push sent successfully.'
          };
        }
      }
      
      return {
        'success': false, 
        'message': data['errorMessage'] ?? data['ResponseDescription'] ?? 'M-Pesa rejected the request.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
