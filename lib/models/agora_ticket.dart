/// Server-issued Agora credentials for one live/call connection.
class AgoraTicket {
  const AgoraTicket({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.isPublisher,
    this.hostUid = 0,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final bool isPublisher;
  final int hostUid;
}

// END OF FILE - lib/models/agora_ticket.dart
