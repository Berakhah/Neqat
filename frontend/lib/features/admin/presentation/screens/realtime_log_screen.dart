import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:frontend/features/admin/domain/entities/log_entry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RealtimeLogScreen extends StatefulWidget {
  const RealtimeLogScreen({super.key});

  @override
  State<RealtimeLogScreen> createState() => _RealtimeLogScreenState();
}

class _RealtimeLogScreenState extends State<RealtimeLogScreen> {
  late WebSocketChannel _channel;
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final String wsUrl = baseUrl.replaceFirst('http', 'ws') + '/ws/admin/logs/';

    _channel = WebSocketChannel.connect(
      Uri.parse(wsUrl),
    );

    _channel.stream.listen(
      (data) {
        try {
          final Map<String, dynamic> jsonData = json.decode(data);
          if (jsonData.containsKey('initial_logs')) {
            // Handle initial batch of logs
            final List<dynamic> initialLogsJson = jsonData['initial_logs'];
            setState(() {
              _logs.clear(); // Clear existing logs if any
              _logs.addAll(initialLogsJson.map((logJson) => LogEntry.fromJson(logJson)).toList());
            });
          } else if (jsonData.containsKey('message')) {
            // Handle real-time single log message
            final LogEntry logEntry = LogEntry.fromJson(jsonData['message']);
            setState(() {
              _logs.add(logEntry);
            });
          }
          _scrollToBottom();
        } catch (e) {
          debugPrint('Error parsing log data: $e, Raw data: $data');
        }
      },
      onDone: () {
        debugPrint('WebSocket connection closed');
        // Optionally try to reconnect
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Admin Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              elevation: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.timestamp}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Action: ${log.action}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Details: ${log.details}'),
                    Text('Outcome: ${log.outcome}'),
                    if (log.user != null) Text('User: ${log.user}'),
                    if (log.objectType != null) Text('Object Type: ${log.objectType}'),
                    if (log.objectId != null) Text('Object ID: ${log.objectId}'),
                    if (log.actionTaken != null) Text('Action Taken: ${log.actionTaken}'),
                    if (log.moderator != null) Text('Moderator: ${log.moderator}'),
                    if (log.beforeStatus != null) Text('Before Status: ${log.beforeStatus}'),
                    if (log.afterStatus != null) Text('After Status: ${log.afterStatus}'),
                    if (log.reason != null && log.reason!.isNotEmpty) Text('Reason: ${log.reason}'),
                    if (log.ipAddress != null) Text('IP Address: ${log.ipAddress}'),
                    if (log.userAgent != null) Text('User Agent: ${log.userAgent}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 