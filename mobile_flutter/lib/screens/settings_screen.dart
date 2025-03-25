import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/services/webrtc_service.dart';
import 'package:mobile_flutter/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _enableLowBandwidthMode;
  late String _selectedVideoQuality;
  late bool _enableEchoCancellation;
  late bool _enableNoiseSuppression;
  late bool _enableAutoGainControl;

  @override
  void initState() {
    super.initState();
    // Initialize settings from the SettingsService
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    _enableLowBandwidthMode = settingsService.enableLowBandwidthMode;
    _selectedVideoQuality = settingsService.videoQuality;
    _enableEchoCancellation = settingsService.enableEchoCancellation;
    _enableNoiseSuppression = settingsService.enableNoiseSuppression;
    _enableAutoGainControl = settingsService.enableAutoGainControl;
  }

  @override
  Widget build(BuildContext context) {
    final webRTCService = Provider.of<WebRTCService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Video Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Low Bandwidth Mode'),
            subtitle: const Text('Reduces video quality to save data'),
            value: _enableLowBandwidthMode,
            onChanged: (value) async {
              setState(() {
                _enableLowBandwidthMode = value;
              });
              // Apply the setting
              await settingsService.setEnableLowBandwidthMode(value);
              webRTCService.setLowBandwidthMode(value);
            },
          ),
          ListTile(
            title: const Text('Video Quality'),
            subtitle: const Text('Higher quality uses more data'),
            trailing: DropdownButton<String>(
              value: _selectedVideoQuality,
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  setState(() {
                    _selectedVideoQuality = newValue;
                  });
                  // Apply the setting
                  await settingsService.setVideoQuality(newValue);
                  webRTCService.setVideoQuality(newValue);
                }
              },
              items: <String>['Low', 'Medium', 'High']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Audio Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Echo Cancellation'),
            subtitle: const Text('Reduces echo during calls'),
            value: _enableEchoCancellation,
            onChanged: (value) async {
              setState(() {
                _enableEchoCancellation = value;
              });
              // Apply the setting
              await settingsService.setEnableEchoCancellation(value);
              webRTCService.setEchoCancellation(value);
            },
          ),
          SwitchListTile(
            title: const Text('Noise Suppression'),
            subtitle: const Text('Reduces background noise'),
            value: _enableNoiseSuppression,
            onChanged: (value) async {
              setState(() {
                _enableNoiseSuppression = value;
              });
              // Apply the setting
              await settingsService.setEnableNoiseSuppression(value);
              webRTCService.setNoiseSuppression(value);
            },
          ),
          SwitchListTile(
            title: const Text('Auto Gain Control'),
            subtitle: const Text('Automatically adjusts microphone volume'),
            value: _enableAutoGainControl,
            onChanged: (value) async {
              setState(() {
                _enableAutoGainControl = value;
              });
              // Apply the setting
              await settingsService.setEnableAutoGainControl(value);
              webRTCService.setAutoGainControl(value);
            },
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            onTap: () {
              // Open GitHub repository
              // You can implement this using url_launcher package
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Reset All Settings'),
            subtitle: const Text('Restore default settings'),
            trailing: const Icon(Icons.restore),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Settings'),
                  content: const Text('Are you sure you want to reset all settings to default?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await settingsService.resetToDefaults();
                setState(() {
                  _enableLowBandwidthMode = settingsService.enableLowBandwidthMode;
                  _selectedVideoQuality = settingsService.videoQuality;
                  _enableEchoCancellation = settingsService.enableEchoCancellation;
                  _enableNoiseSuppression = settingsService.enableNoiseSuppression;
                  _enableAutoGainControl = settingsService.enableAutoGainControl;
                });
                
                // Apply default settings to WebRTC
                webRTCService.setLowBandwidthMode(settingsService.enableLowBandwidthMode);
                webRTCService.setVideoQuality(settingsService.videoQuality);
                webRTCService.setEchoCancellation(settingsService.enableEchoCancellation);
                webRTCService.setNoiseSuppression(settingsService.enableNoiseSuppression);
                webRTCService.setAutoGainControl(settingsService.enableAutoGainControl);
              }
            },
          ),
        ],
      ),
    );
  }
}