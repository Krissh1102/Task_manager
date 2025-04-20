import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  User? _user;
  
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  
  AuthService() {
    _initialize();
  }
  
  void _initialize() {
    _user = _supabase.auth.currentUser;
    _isAuthenticated = _user != null;
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      if (event == AuthChangeEvent.signedIn) {
        _user = data.session?.user;
        _isAuthenticated = true;
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _isAuthenticated = false;
      }
      
      notifyListeners();
    });
  }
  
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}