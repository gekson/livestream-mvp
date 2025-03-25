import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_flutter/screens/room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  bool _isGeneratingRoomId = false;

  @override
  void initState() {
    super.initState();
    _generateRoomId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  void _generateRoomId() {
    setState(() {
      _isGeneratingRoomId = true;
    });

    // Generate a random room ID
    final uuid = const Uuid().v4();
    final shortId = uuid.substring(0, 8);
    
    setState(() {
      _roomIdController.text = shortId;
      _isGeneratingRoomId = false;
    });
  }

  void _createRoom() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          roomId: _roomIdController.text,
          username: _nameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a new livestream room',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isGeneratingRoomId
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.refresh),
                  onPressed: _isGeneratingRoomId ? null : _generateRoomId,
                  tooltip: 'Generate new Room ID',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _createRoom,
                child: const Text('Create Room', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Share the Room ID with others so they can join your room.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}