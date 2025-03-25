import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/models/user.dart';
import 'package:mobile_flutter/services/socket_service.dart';

class RoomService extends ChangeNotifier {
  final SocketService _socketService;
  String? currentRoomId;
  List<RoomUser> users = [];
  bool isHost = false;
  
  RoomService(this._socketService) {
    _setupListeners();
  }
  
  void _setupListeners() {
    _socketService.socket.on('users', (data) {
      _handleUsersUpdate(data);
    });
  }
  
  void _handleUsersUpdate(List<dynamic> usersData) {
    users = usersData.map((userData) {
      final isMe = userData['id'] == _socketService.socket.id;
      return RoomUser.fromJson(userData, isMe: isMe);
    }).toList();
    
    notifyListeners();
  }
  
  void joinRoom(String roomId, String username, {bool asHost = false}) {
    currentRoomId = roomId;
    isHost = asHost;
    _socketService.joinRoom(roomId, username);
    notifyListeners();
  }
  
  void leaveRoom() {
    if (currentRoomId != null) {
      _socketService.socket.emit('leave-room', {'roomId': currentRoomId});
      currentRoomId = null;
      users = [];
      isHost = false;
      notifyListeners();
    }
  }
  
  RoomUser? getLocalUser() {
    return users.firstWhere(
      (user) => user.isMe,
      orElse: () => RoomUser(
        id: _socketService.socket.id ?? '',
        username: _socketService.username ?? 'Me',
        isMe: true,
      ),
    );
  }
  
  List<RoomUser> getRemoteUsers() {
    return users.where((user) => !user.isMe).toList();
  }
}