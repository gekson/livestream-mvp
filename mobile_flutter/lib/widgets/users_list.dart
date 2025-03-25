import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/services/socket_service.dart';
import 'package:mobile_flutter/models/user.dart';

class UsersList extends StatelessWidget {
  const UsersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        final users = socketService.users.map((userData) {
          final isMe = userData['id'] == socketService.socket.id;
          return RoomUser.fromJson(userData, isMe: isMe);
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: 8),
                    Text(
                      'Participants (${users.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isMe ? Colors.blue : Colors.grey,
                        child: Text(
                          user.username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user.username,
                        style: TextStyle(
                          fontWeight: user.isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: user.isMe
                          ? const Chip(
                              label: Text('You'),
                              backgroundColor: Colors.blue,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}