import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/storage.dart';

// AdMob import - uncomment when ready
// import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = Storage();
  await storage.init();

  // AdMob init - uncomment when ready
  // await MobileAds.instance.initialize();

  runApp(BlockArenaApp(storage: storage));
}



class BlockArenaApp extends StatelessWidget {
  final Storage storage;
  const BlockArenaApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Arena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(storage: storage),
    );
  }
}
