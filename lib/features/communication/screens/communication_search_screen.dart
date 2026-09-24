import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/communication_service.dart';
import 'chat_list_screen.dart';

class CommunicationSearchScreen extends StatefulWidget {
  const CommunicationSearchScreen({super.key});

  @override
  State<CommunicationSearchScreen> createState() => _CommunicationSearchScreenState();
}

class _CommunicationSearchScreenState extends State<CommunicationSearchScreen> {
  final _controller = TextEditingController();
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'ابحث عن محادثة أو إعلان...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    setState(() => _searched = true);
                    await context.read<CommunicationService>().getConversations(
                          search: _controller.text.trim(),
                        );
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_searched)
              const Text('ابدأ بالكتابة ثم اضغط بحث')
            else
              const Text('جاري عرض النتائج في قائمة المحادثات...'),
          ],
        ),
      ),
    );
  }
}
