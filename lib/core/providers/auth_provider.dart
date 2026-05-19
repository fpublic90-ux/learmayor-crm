import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

enum UserRole { admin, employee, intern }

class AuthProvider extends ChangeNotifier {
  // Secure storage for sensitive JWT token
  final _storage = const FlutterSecureStorage();
  
  // Current user data
  String? _userName;
  String? _userEmail;
  String? _token;
  UserRole _role = UserRole.employee;
  
  // Admin's profile photo stored locally
  String? _profilePicUrl;
  
  // Flag for demo/offline access
  bool _isDemoUser = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allUsers = [];

  AuthProvider() {
    _loadSession();
  }

  // Getters
  String? get profilePicUrl => _profilePicUrl;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  UserRole get role => _role;
  bool get isAdmin => _role == UserRole.admin;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null || _isDemoUser;
  List<Map<String, dynamic>> get allUsers => _allUsers;

  // Loads session from storage
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _profilePicUrl = prefs.getString('admin_photo');
    _isDemoUser = prefs.getBool('is_demo') ?? false;
    
    // Determine role based on email or saved role
    final savedRole = prefs.getString('user_role');
    // Determine role based on saved state
    if (savedRole != null) {
      _role = UserRole.values.firstWhere((e) => e.name == savedRole, orElse: () => UserRole.employee);
    } else if (_userEmail == 'jafarevx123@gmail.com') {
      _role = UserRole.admin; // Emergency fallback for root admin
    } else {
      _role = UserRole.employee;
    }
    
    debugPrint('🔐 Auth: Session Loaded. Token present: ${_token != null}');
    
    if (_token != null) {
      _verifyToken();
    }
    notifyListeners();
  }

  // Verify token with backend
  Future<void> _verifyToken() async {
    try {
      debugPrint('🌐 Auth: Verifying Token...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('⚠️ Auth: Token Invalid (Status ${response.statusCode})');
        logout();
      } else {
        debugPrint('✅ Auth: Token Verified');
      }
    } catch (e) {
      debugPrint('ℹ️ Auth: Verification skipped/failed (Offline)');
    }
  }

  // Custom Login with optional role override for registration
  Future<void> login(String email, String password, {UserRole? manualRole}) async {
    _isLoading = true;
    notifyListeners();
    
    int attempts = 0;
    const int maxAttempts = 3;
    
    debugPrint('🚀 Auth: Login Attempt Started for $email');
    
    try {
      while (attempts < maxAttempts) {
        attempts++;
        try {
          debugPrint('📡 Auth: Sending Request (Attempt $attempts)...');
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          ).timeout(Duration(seconds: 15 * attempts));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            _token = data['token'];
            _userName = data['name'];
            _userEmail = data['email'];
            
            if (data['role'] != null) {
              _role = UserRole.values.firstWhere(
                (e) => e.name == data['role'], 
                orElse: () => UserRole.employee
              );
            } else if (_userEmail == 'jafarevx123@gmail.com') {
              _role = UserRole.admin;
            } else if (manualRole != null) {
              _role = manualRole;
            } else {
              _role = UserRole.employee;
            }
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwt_token', _token!);
            await prefs.setString('user_name', _userName!);
            await prefs.setString('user_email', _userEmail!);
            await prefs.setString('user_role', _role.name);
            
            debugPrint('✅ Auth: Login Success as ${_role.name}!');
            return; 
          } else {
            final data = jsonDecode(response.body);
            final error = data['error'] ?? 'Login failed';
            debugPrint('❌ Auth: Backend Rejected (Status ${response.statusCode}): $error');
            
            // Critical Fix: Do NOT retry on 4xx (Client errors) or Rate Limits
            if (response.statusCode >= 400 && response.statusCode < 500) {
              throw Exception(error);
            }
            
            throw Exception('Server error (${response.statusCode})');
          }
        } on Exception catch (e) {
          debugPrint('⏳ Auth: Attempt $attempts failed: $e');
          
          // Only retry if it's a potential temporary network issue or server glitch
          final errorStr = e.toString().toLowerCase();
          final isRateLimit = errorStr.contains('too many attempts') || errorStr.contains('429');
          final isAuthError = errorStr.contains('invalid') || errorStr.contains('unauthorized');

          if (attempts >= maxAttempts || isRateLimit || isAuthError) {
             rethrow;
          }
          
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void finishLogin() {
    notifyListeners();
  }

  Future<void> refreshLocalProfile({required String name, String? email}) async {
    _userName = name;
    if (email != null) _userEmail = email;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName!);
    if (email != null) await prefs.setString('user_email', _userEmail!);
    
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email, String? oldPassword, String? newPassword, String? photoUrl}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (oldPassword != null) 'oldPassword': oldPassword,
          if (newPassword != null) 'newPassword': newPassword,
          if (photoUrl != null) 'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userName = data['name'];
        _userEmail = data['email'];
        _token = data['token'];
        _profilePicUrl = data['photoUrl'] ?? _profilePicUrl;
        
        await _storage.write(key: 'jwt_token', value: _token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
        if (_profilePicUrl != null) {
          await prefs.setString('admin_photo', _profilePicUrl!);
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Update failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload'));
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> updateProfilePic(String url) async {
    _profilePicUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_photo', url);
    notifyListeners();
  }

  void bypassLogin() {
    _isDemoUser = true;
    notifyListeners();
  }

  // Fetch all registered users (Admin only)
  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/users'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('📡 Auth: Users Sync Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _allUsers = data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Auth: Users Sync Failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a user account permanently (Admin only)
  Future<bool> deleteUser(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/auth/users/$email'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Auth: User $email deleted from database');
        await fetchAllUsers(); // Refresh list
        return true;
      } else {
        final data = jsonDecode(response.body);
        debugPrint('❌ Auth: Delete failed: ${data['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authoritatively update a user's role (Admin only)
  Future<bool> updateUserRole(String email, UserRole role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/users/$email/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'role': role.name}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Auth: Role for $email updated to ${role.name}');
        await fetchAllUsers(); // Refresh the list
        return true;
      } else {
        final data = jsonDecode(response.body);
        debugPrint('❌ Auth: Role update failed: ${data['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating role: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Wake up the server early to handle cold starts
  Future<void> warmup() async {
    try {
      // Just a simple GET to wake up the Render instance
      await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/verify')).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore errors, we just want to trigger the server boot
    }
  }

  Future<void> logout() async {
    // Phase 1: Synchronous Invalidation (Total UI Stop)
    _token = null;
    _userName = null;
    _userEmail = null;
    _isDemoUser = false;
    _role = UserRole.employee; // Reset to default
    
    // Notify UI immediately to trigger redirection before async disk I/O
    notifyListeners();

    // Phase 2: Asynchronous Persistence Teardown (Clean Background)
    try {
      await _storage.deleteAll(); // Clear secure JWT
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Total wipe for safety
    } catch (e) {
      debugPrint('⚠️ Auth: Storage cleanup error: $e');
    }
  }
}
