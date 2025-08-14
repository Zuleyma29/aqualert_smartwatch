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

  // Función para validar código consultando Firebase Firestore
  Future<Map<String, String>?> _validateCodeFromFirebase(String code) async {
    try {
      // Consultar la colección 'usuarios' donde 'id_unico' sea igual al código ingresado
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
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Verificar si todos los campos están llenos
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _verifyCode() async {
    String code = _controllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Por favor, ingresa un código de 6 caracteres.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Consultar Firebase para validar el código
    Map<String, String>? userData = await _validateCodeFromFirebase(code);

    if (userData != null) {
      // Código válido - navegar a la pantalla principal
      HapticFeedback.lightImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TomeAguaScreen()),
      );
    } else {
      // Código inválido
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Código inválido. Inténtalo de nuevo.';
        _isLoading = false;
      });
      _clearCode();
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double shortestSide = screenSize.shortestSide;
    // Optimizado para smartwatch - mejor escalado para pantallas pequeñas
    final double scaleFactor =
        shortestSide < 250 ? shortestSide / 150.0 : shortestSide / 200.0;

    return Scaffold(
      backgroundColor: const Color(0xFFDCEEFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo y título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ic_launcher.png',
                        width: 30 * scaleFactor,
                        height: 30 * scaleFactor,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Text(
                        'Aqualert',
                        style: TextStyle(
                          fontSize: 24 * scaleFactor,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15 * scaleFactor),

                  // Título de autenticación
                  Text(
                    'Ingresa tu código de acceso',
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003366),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10 * scaleFactor),

                  // Campos de código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        width: math.max(20 * scaleFactor, 30),
                        height: math.max(30 * scaleFactor, 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _controllers[index].text.isNotEmpty
                                    ? const Color(0xFF4A90E2)
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 18 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003366),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                          ],
                          onChanged: (value) => _onCodeChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 10 * scaleFactor),

                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(8 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12 * scaleFactor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: 8 * scaleFactor),

                  // Indicador de carga
                  if (_isLoading)
                    SizedBox(
                      width: 20 * scaleFactor,
                      height: 20 * scaleFactor,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A90E2),
                      ),
                    ),

                  SizedBox(height: 15 * scaleFactor),

                  // Información adicional
                  Text(
                    'Código de 6 dígitos',
                    style: TextStyle(
                      fontSize: 12 * scaleFactor,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 5 * scaleFactor),
                  Text(
                    'Solo números',
                    style: TextStyle(
                      fontSize: 10 * scaleFactor,
                      color: Colors.grey.shade500,
                    ),
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
