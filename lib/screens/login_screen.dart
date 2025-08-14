import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tome_agua.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;

  Future<Map<String, String>?> _validateCodeFromFirebase(String code) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('id_unico', isEqualTo: code)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return {
          'usuario': data['usuario'] ?? 'Usuario',
          'correo': data['correo'] ?? '',
          'uid_firebase': data['uid_firebase'] ?? doc.id,
        };
      }
      return null;
    } catch (e) {
      print('Error al consultar Firebase: $e');
      return null;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();

    if (_controllers.every((c) => c.text.isNotEmpty)) _verifyCode();
  }

  void _verifyCode() async {
    String code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Ingresa un código de 6 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    Map<String, String>? userData = await _validateCodeFromFirebase(code);

    if (userData != null) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TomeAguaScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Código inválido.';
        _isLoading = false;
      });
      _clearCode();
    }
  }

  void _clearCode() {
    for (var c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double shortest = screenSize.shortestSide;
    // Escala basada en pantalla
    final double scale = shortest / 150;

    return Scaffold(
      backgroundColor: const Color(0xFFDCEEFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5 * scale),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ic_launcher.png',
                        width: 20 * scale,
                        height: 20 * scale,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        'Aqualert',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),

                  Text(
                    'Ingresa tu código',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003366),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6 * scale),

                  // Campos de código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      return Flexible(
                        child: Container(
                          height: 28 * scale,
                          margin: EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  _controllers[i].text.isNotEmpty
                                      ? const Color(0xFF4A90E2)
                                      : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF003366),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]'),
                              ),
                            ],
                            onChanged: (v) => _onCodeChanged(v, i),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 6 * scale),

                  // Error
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(4 * scale),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10 * scale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: 4 * scale),

                  if (_isLoading)
                    SizedBox(
                      width: 16 * scale,
                      height: 16 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A90E2),
                      ),
                    ),

                  SizedBox(height: 6 * scale),

                  // Información adicional
                  Text(
                    '6 dígitos, solo números',
                    style: TextStyle(
                      fontSize: 8 * scale,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
