import 'package:flutter/material.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key, required this.title});

  final String title;

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _startProvisioning() async {
    final provisioner = Provisioner.espTouch();

    provisioner.listen((response) {
      Navigator.of(context).pop(response);
    });

    provisioner.start(ProvisioningRequest.fromStrings(
      ssid: ssidController.text,
      bssid: '00:00:00:00:00:00',
      password: passwordController.text,
    ));

    ProvisioningResponse? response = await showDialog<ProvisioningResponse>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Provisioning'),
          content: const Text('Provisioning started. Please wait...'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );

    if(provisioner.running) {
      provisioner.stop();
    }

    if (response != null) {
      _onDeviceProvisioned(response);
    }
  }

  _onDeviceProvisioned(ProvisioningResponse response) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Device provisioned'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Device successfully connected to the ${ssidController.text} network'),
              SizedBox.fromSize(size: const Size.fromHeight(20)),
              const Text('Device:'),
              Text('IP: ${response.ipAddressText}'),
              Text('BSSID: ${response.bssidText}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.cell_tower,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox.fromSize(size: const Size.fromHeight(20)),
              const Text(
                'Connect device to Wi-Fi network using ESP-Touch protocol',
                textAlign: TextAlign.center,
              ),
              SizedBox.fromSize(size: const Size.fromHeight(40)),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'SSID (Network name)',
                ),
                controller: ssidController,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                controller: passwordController,
              ),
              SizedBox.fromSize(size: const Size.fromHeight(40)),
              ElevatedButton(
                onPressed: _startProvisioning,
                child: const Text('Start provisioning'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}