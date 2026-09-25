import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:errasoft/core/di/dependency_injection.dart';
import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/firebase_options.dart';
import 'package:errasoft/features/auth/login/presentation/cubit/login_cubit.dart';
import 'package:errasoft/features/auth/presentation/screens/landing_screen.dart';
import 'package:errasoft/features/auth/register/home/presentation/screens/home_screen.dart';
import 'package:errasoft/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalStorage.init();
  await setupGetIt();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => getIt<LoginCubit>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: FutureBuilder<bool>(
          future: LocalStorage.instance.isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return snapshot.data == true
                ? const HomeScreen()
              : const LandingScreen();
          },
        ),
      ),
    );
  }
}
