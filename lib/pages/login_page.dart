import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _isRegister = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        await ApiService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation:
              _passwordConfirmationController.text,
        );

        if (!mounted) return;

        // Jika endpoint register belum memberikan token,
        // pengguna perlu login menggunakan akun yang baru dibuat.
        if (ApiService.token == null) {
          setState(() => _isRegister = false);
          _passwordController.clear();
          _passwordConfirmationController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi berhasil. Silakan masuk dengan akunmu.',
              ),
            ),
          );
          return;
        }
      } else {
        await ApiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      AppState.instance.email = _emailController.text.trim();

      // Gunakan nama dari server jika tersedia.
      try {
        final user = await ApiService.getUser();

        final serverName = user['name']?.toString();

        if (serverName != null && serverName.isNotEmpty) {
          AppState.instance.name = serverName;
        }
      } catch (_) {
        // Login tetap dilanjutkan jika permintaan profil gagal.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegister
                ? 'Akun berhasil dibuat. Selamat datang di StraFit!'
                : 'Berhasil masuk ke StraFit.',
          ),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      var message = error.toString().replaceFirst('Exception: ', '');

      // Membuat pesan validasi Laravel lebih mudah dipahami.
      if (message.toLowerCase().contains('unauthorized') ||
          message.toLowerCase().contains('invalid credentials')) {
        message = 'Email atau password salah.';
      } else if (message.toLowerCase().contains('socketexception') ||
          message.toLowerCase().contains('failed host lookup')) {
        message =
            'Tidak dapat terhubung ke server Laravel. '
            'Pastikan server sedang berjalan.';
      } else if (message.toLowerCase().contains('clientexception')) {
        message =
            'Koneksi ke server gagal. Periksa server dan konfigurasi jaringan.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 96,
                      width: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            kOrange,
                            Color(0xFFFF8B50),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kOrange.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'StraFit',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _isRegister
                          ? 'Buat akun dan mulai perjalanan sehatmu.'
                          : 'Track your move. Improve your pace.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Nama lengkap',
                        ),
                        validator: (value) {
                          if (!_isRegister) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }

                          if (value.trim().length < 2) {
                            return 'Nama minimal 2 karakter';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Email',
                      ),
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())) {
                          return 'Masukkan email yang valid';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }

                        return null;
                      },
                    ),

                    if (_isRegister) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordConfirmationController,
                        obscureText: _hideConfirmation,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_reset),
                          hintText: 'Konfirmasi password',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideConfirmation = !_hideConfirmation;
                              });
                            },
                            icon: Icon(
                              _hideConfirmation
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (!_isRegister) return null;

                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }

                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak sama';
                          }

                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _continue,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isRegister ? 'Daftar' : 'Masuk',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isRegister = !_isRegister;
                              });
                            },
                      child: Text(
                        _isRegister
                            ? 'Sudah punya akun? Masuk'
                            : 'Belum punya akun? Daftar',
                        style: const TextStyle(
                          color: kInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Terhubung dengan server StraFit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
