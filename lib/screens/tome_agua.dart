import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Para Timer

class TomeAguaScreen extends StatefulWidget {
  const TomeAguaScreen({Key? key}) : super(key: key);

  @override
  _TomeAguaScreenState createState() => _TomeAguaScreenState();
}

class _TomeAguaScreenState extends State<TomeAguaScreen> {
  int cantidadTomada = 0;
  int metaDiaria = 2000; // Valor por defecto, se cargará desde la base de datos
  String? userId;
  bool isLoading = true;
  Timer? _autoUpdateTimer; // Timer para actualización automática

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startAutoUpdate(); // Iniciar actualización automática
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel(); // Cancelar timer al salir
    super.dispose();
  }

  // Función para iniciar la actualización automática cada 3 segundos
  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (userId != null) {
        _loadWaterProgress(); // Actualizar datos desde Firebase
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('uid_firebase');

      // Asegurar que el usuario permanezca logueado
      if (userId != null) {
        // Guardar nuevamente para asegurar persistencia
        await prefs.setString('uid_firebase', userId!);
        await _loadWaterProgress();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadWaterProgress() async {
    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('Loading data for date: $dateString'); // Debug
      print('User ID: $userId'); // Debug

      // Cargar el progreso del día actual
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('metas')
              .doc(dateString)
              .get();

      print('Document exists: ${doc.exists}'); // Debug

      if (doc.exists) {
        final data = doc.data()!;
        print('Document data: $data'); // Debug

        setState(() {
          cantidadTomada = data['agua_tomada'] ?? 0;
          metaDiaria = data['meta_diaria'] ?? 2000;
        });

        print(
          'Loaded - Cantidad tomada: $cantidadTomada, Meta: $metaDiaria',
        ); // Debug
      } else {
        print('No document found for today, using defaults');
        setState(() {
          cantidadTomada = 0;
          metaDiaria = 2000;
        });
      }
    } catch (e) {
      print('Error loading water progress: $e');
    }
  }

  Future<void> _saveWaterProgress() async {
    if (userId == null) {
      print('ERROR: userId is null, cannot save progress');
      return;
    }

    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('=== SAVING WATER PROGRESS ===');
      print('User ID: $userId');
      print('Date: $dateString');
      print('Cantidad tomada: $cantidadTomada ml');
      print('Meta diaria: $metaDiaria ml');
      print('Path: usuarios/$userId/metas/$dateString');

      final docRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('metas')
          .doc(dateString);

      final dataToSave = {
        'fecha': dateString,
        'agua_tomada': cantidadTomada,
        'meta_diaria': metaDiaria,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('Data to save: $dataToSave');

      await docRef.set(dataToSave, SetOptions(merge: true));

      print('✅ Data saved successfully!');

      // Verificar que se guardó correctamente
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('✅ Verification: Document exists with data: ${savedDoc.data()}');
      } else {
        print('❌ Verification: Document was not saved!');
      }
    } catch (e) {
      print('❌ Error saving water progress: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  void _mostrarConfirmacionReinicio(double scaleFactor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10 * scaleFactor,
            vertical: 8 * scaleFactor,
          ),
          backgroundColor: const Color(0xFFDCEEFF),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Reiniciar contador?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6 * scaleFactor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón ❌ rojo
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    iconSize: 20 * scaleFactor,
                  ),
                  // Botón ✅
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        cantidadTomada = 0;
                      });
                      await _saveWaterProgress();
                      Navigator.of(context).pop(); // Cierra el diálogo
                    },
                    icon: const Icon(Icons.check, color: Colors.green),
                    iconSize: 20 * scaleFactor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFDCEEFF),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
        ),
      );
    }

    double porcentaje = cantidadTomada / metaDiaria;
    if (porcentaje > 1.0) porcentaje = 1.0;

    Color progressColor =
        porcentaje < 0.5 ? Colors.lightBlueAccent : Colors.blueAccent;

    final Size screenSize = MediaQuery.of(context).size;
    final double shortestSide = screenSize.shortestSide;
    final double longestSide = screenSize.longestSide;
    final double aspectRatio = longestSide / shortestSide;

    // Detectar si es pantalla rectangular (aspect ratio > 1.5)
    bool isRectangular = aspectRatio > 1.5;

    // Ajustar el factor de escala basado en el tamaño y forma de pantalla
    double scaleFactor;
    if (isRectangular) {
      // Para pantallas rectangulares, usar el lado más corto como referencia
      scaleFactor = shortestSide / 180;
    } else {
      // Para pantallas cuadradas o casi cuadradas
      scaleFactor = shortestSide / 200;
    }

    // Ajustes especiales para pantallas muy pequeñas
    if (shortestSide < 150) {
      scaleFactor = shortestSide / 120;
    } else if (shortestSide < 250) {
      scaleFactor = shortestSide / 140;
    }

    scaleFactor = scaleFactor.clamp(
      0.5,
      1.8,
    ); // Ampliar el rango para mejor adaptabilidad

    return Scaffold(
      backgroundColor: const Color(0xFFDCEEFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ic_launcher.png',
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                      ),
                      SizedBox(width: 6 * scaleFactor),
                      Text(
                        'Aqualert',
                        style: TextStyle(
                          fontSize: 18 * scaleFactor,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height:
                        isRectangular
                            ? 8 * scaleFactor
                            : (shortestSide < 200
                                ? 6 * scaleFactor
                                : 12 * scaleFactor),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: (isRectangular ? 80 : 90) * scaleFactor,
                        height: (isRectangular ? 80 : 90) * scaleFactor,
                        child: CircularProgressIndicator(
                          value: porcentaje,
                          strokeWidth: (isRectangular ? 5 : 6) * scaleFactor,
                          backgroundColor: Colors.white,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        '${(porcentaje * 100).round()}%',
                        style: TextStyle(
                          fontSize: (isRectangular ? 14 : 16) * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height:
                        isRectangular
                            ? 6 * scaleFactor
                            : (shortestSide < 200
                                ? 5 * scaleFactor
                                : 10 * scaleFactor),
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: (isRectangular ? 10 : 12) * scaleFactor,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: 'Has tomado: '),
                        TextSpan(
                          text: '$cantidadTomada ml',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (isRectangular ? 12 : 14) * scaleFactor,
                          ),
                        ),
                        TextSpan(text: ' / $metaDiaria ml'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height:
                        isRectangular
                            ? 8 * scaleFactor
                            : (shortestSide < 200
                                ? 6 * scaleFactor
                                : 12 * scaleFactor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            if (cantidadTomada < metaDiaria) {
                              int nuevoTotal = cantidadTomada + 250;
                              if (nuevoTotal >= metaDiaria) {
                                cantidadTomada = metaDiaria;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "¡Felicidades! Completaste tu meta 🎉",
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                cantidadTomada = nuevoTotal;
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Ya completaste tu meta diaria 💧",
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                          // Guardar el progreso en Firebase
                          await _saveWaterProgress();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: EdgeInsets.symmetric(
                            horizontal: (isRectangular ? 10 : 12) * scaleFactor,
                            vertical: (isRectangular ? 6 : 8) * scaleFactor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isRectangular ? 12 : 15,
                            ),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          isRectangular ? 'Tomé\nagua' : 'Tomé agua',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (isRectangular ? 10 : 12) * scaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width:
                            isRectangular
                                ? 6 * scaleFactor
                                : (shortestSide < 200
                                    ? 5 * scaleFactor
                                    : 10 * scaleFactor),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _mostrarConfirmacionReinicio(scaleFactor);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFDCEEFF),
                          padding: EdgeInsets.symmetric(
                            horizontal: (isRectangular ? 10 : 12) * scaleFactor,
                            vertical: (isRectangular ? 6 : 8) * scaleFactor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isRectangular ? 12 : 15,
                            ),
                          ),
                        ),
                        child: Text(
                          'Reiniciar',
                          style: TextStyle(
                            fontSize: (isRectangular ? 10 : 12) * scaleFactor,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
