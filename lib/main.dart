import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';
import 'theme/neon_theme.dart';
import 'services/background_music_service.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  //Role ng main.dart is to make sure na nakakapag communicate ung flutter and supabase such as receiving data.
  //Note from me: This is a very very dangerous thing to expose to those who know what they are doing, kaya better to keep the url PRIVATE.
  //And if gusto mo ipahiram ung code sa iba. rewrite url and anonKey to be [INSERT YOUR OWN KEY], especially if plano mo pa gamitin ung supabase project.
  await Supabase.initialize(
    url: "https://nisssojyxkmiletzqjim.supabase.co", //Wag mo isend tong url in any kind of messages or public chats. Very dangerous.
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pc3Nzb2p5eGttaWxldHpxamltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2Nzk1NDEsImV4cCI6MjA3OTI1NTU0MX0.pX0qwuNXvSFXeIt9H_zemGJRbJpnKQFVkIeKZ2c2sxk",
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver {

  final BackgroundMusicService _music =
      BackgroundMusicService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _music.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override //For music, such as handling interruptions, playing when inside the app.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _music.pause();
    } else if (state == AppLifecycleState.resumed) {
      _music.resume();
    }
  }

  //Overall theme ng app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.theme,
      home: SignInPage(),
    );
  }
}
