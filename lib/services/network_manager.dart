import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class NetworkManager {
  static const _baseUrl = 'https://www.opensplittime.org/';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/v1/auth'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'cache-control': 'no-cache',
      },
      body: {
        'user[email]': email,
        'user[password]': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'] ?? '');

      developer.log(
        'Login successful, token saved.',
        name: 'NetworkManager.login',
      );

      return data;
    } else {
      throw Exception('Login failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, List<String>>> fetchEventDetails() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${_baseUrl}api/v1/events?filter[editable]=true'),
      headers: {
        'Authorization': token,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Build a map of event name -> aid stations
      Map<String, List<String>> eventAidStations = {};
      if (data['data'] != null && data['data'] is List) {
        for (var event in data['data']) {
          if (event['attributes'] != null && event['attributes']['name'] != null) {
            final eventName = event['attributes']['name'].toString();
            final splits = event['attributes']['splitNames'];
            if (splits != null && splits is List) {
              eventAidStations[eventName] = List<String>.from(splits);
            } else {
              eventAidStations[eventName] = [];
            }
          }
        }
      }
      return eventAidStations;
    } else if (response.statusCode == 401) {
      throw Exception('\nAuthentication failed. Please try logging in again.');
    } else {
      throw Exception('\nFailed to load events (${response.statusCode}): ${response.body}');
    }
  }
}
