# Livestream MVP Flutter App

A Flutter application for video conferencing and livestreaming that connects to a MediaSoup-based WebRTC server.

## Features

- Real-time video conferencing
- Chat messaging
- Room-based communication
- WebRTC integration with MediaSoup
- Responsive design for mobile and tablet

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or Xcode for mobile development
- A running instance of the MediaSoup server

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:

```bash
flutter pub get
```

socket = io.io('http://YOUR_SERVER_IP:3001', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
});
