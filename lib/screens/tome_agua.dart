import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback

class TomeAguaScreen extends StatefulWidget {
  const TomeAguaScreen({Key? key}) : super(key: key);

  @override
  _TomeAguaScreenState createState() => _TomeAguaScreenState();
}

class _TomeAguaScreenState extends State<TomeAguaScreen> {
  int cantidadTomada = 500;
  final int metaDiaria = 2000;

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
                    onPressed: () {
                      setState(() {
                        cantidadTomada = 0;
                      });
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
    double porcentaje = cantidadTomada / metaDiaria;
    if (porcentaje > 1.0) porcentaje = 1.0;

    Color progressColor =
        porcentaje < 0.5 ? Colors.lightBlueAccent : Colors.blueAccent;

    final Size screenSize = MediaQuery.of(context).size;
    final double shortestSide = screenSize.shortestSide;
    final double scaleFactor = shortestSide / 200.0;

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
                  SizedBox(height: 12 * scaleFactor),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90 * scaleFactor,
                        height: 90 * scaleFactor,
                        child: CircularProgressIndicator(
                          value: porcentaje,
                          strokeWidth: 6 * scaleFactor,
                          backgroundColor: Colors.white,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        '${(porcentaje * 100).round()}%',
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * scaleFactor),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12 * scaleFactor,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: 'Has tomado: '),
                        TextSpan(
                          text: '$cantidadTomada ml',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scaleFactor,
                          ),
                        ),
                        TextSpan(text: ' / $metaDiaria ml'),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 8 * scaleFactor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Tomé agua',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12 * scaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scaleFactor),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _mostrarConfirmacionReinicio(scaleFactor);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFDCEEFF),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 8 * scaleFactor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Reiniciar',
                          style: TextStyle(
                            fontSize: 12 * scaleFactor,
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
