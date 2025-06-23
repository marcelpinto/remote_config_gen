import 'package:example/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../generated/remote_config_params.gen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Config Gen Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(
            int.parse(
              RemoteConfigParams.uiSettings.primaryColor.getValue().replaceAll(
                '#',
                '0xFF',
              ),
            ),
          ),
          brightness:
              RemoteConfigParams.uiSettings.darkMode.getValue()
                  ? Brightness.dark
                  : Brightness.light,
        ),
        useMaterial3: true,
        brightness:
            RemoteConfigParams.uiSettings.darkMode.getValue()
                ? Brightness.dark
                : Brightness.light,
      ),
      home: const RemoteConfigDemo(),
    );
  }
}

class RemoteConfigDemo extends StatelessWidget {
  const RemoteConfigDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Remote Config Gen Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Remote Config Parameters:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildParamTile('Welcome Message', RemoteConfigParams.welcomeMessage),
          _buildParamTile('Feature Enabled', RemoteConfigParams.featureEnabled),
          _buildParamTile('Max Retry Count', RemoteConfigParams.maxRetryCount),
          _buildParamTile('API Timeout', RemoteConfigParams.apiTimeout),
          _buildParamTile(
            'Languages Config',
            RemoteConfigParams.languagesConfig,
          ),
          const SizedBox(height: 16),
          const Text(
            'UI Settings Group:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildParamTile(
            'Primary Color',
            RemoteConfigParams.uiSettings.primaryColor,
          ),
          _buildParamTile('Dark Mode', RemoteConfigParams.uiSettings.darkMode),
          _buildParamTile(
            'Button Color',
            RemoteConfigParams.uiSettings.buttonColor,
          ),
          _buildParamTile(
            'Animation Duration',
            RemoteConfigParams.uiSettings.animationDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildParamTile<T>(String label, RemoteConfigParam<T> param) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          "Key: ${param.key}\nCurrent Value: ${param.getValue()}\nDefault Value: ${param.defaultValue}",
        ),
      ),
    );
  }
}
