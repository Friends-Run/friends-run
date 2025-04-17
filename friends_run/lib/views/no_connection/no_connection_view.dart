import 'package:flutter/material.dart';
import 'package:friends_run/core/utils/colors.dart';

class NoConnectionView extends StatelessWidget {
  const NoConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off, color: AppColors.white, size: 64),
            SizedBox(height: 20),
            Text(
              "Sem conexão com a internet",
              style: TextStyle(color: AppColors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Conecte-se a uma rede para continuar usando o app.",
              style: TextStyle(color: AppColors.greyLight, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
