import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/services/socket_service.dart';
import 'package:mobile_flutter/services/logger_service.dart';

class ServerToggleButton extends StatelessWidget {
  const ServerToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    
    return IconButton(
      icon: const Icon(Icons.dns),
      tooltip: 'Server Settings',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Server Connection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current server: ${socketService.currentServerUrl}'),
                const SizedBox(height: 20),
                const Text('Select server address:'),
                const SizedBox(height: 10),
                _buildServerOption(context, socketService, 'Local Device (192.168.0.37:3001)', 'http://192.168.0.37:3001'),
                _buildServerOption(context, socketService, 'Emulator (10.0.2.2:3001)', 'http://10.0.2.2:3001'),
                _buildServerOption(context, socketService, 'Localhost (localtunnel)', 'https://slow-books-remain.loca.lt'),
                _buildServerOption(context, socketService, 'AVD Localhost (10.0.3.2:3001)', 'http://10.0.3.2:3001'),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Custom Server URL',
                    hintText: 'http://your-server-ip:3001',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      socketService.connectToServer(value);
                      Navigator.pop(context);
                      _showConnectionMessage(context, value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildServerOption(BuildContext context, SocketService socketService, String label, String url) {
    return ListTile(
      title: Text(label),
      onTap: () {
        socketService.connectToServer(url);
        Navigator.pop(context);
        _showConnectionMessage(context, url);
      },
    );
  }
  
  void _showConnectionMessage(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}