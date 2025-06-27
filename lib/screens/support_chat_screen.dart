import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({Key? key}) : super(key: key);

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final user = FirebaseAuth.instance.currentUser!;
  bool get isAdmin => user.email == 'admin@gmail.com';

  // For admin to select a user
  String? selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Support Panel' : 'Support Chat'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          if (isAdmin) _buildUserSelector(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('supportChats')
                  .where('uid', isEqualTo: isAdmin ? selectedUserId ?? '' : user.uid)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (!isAdmin || selectedUserId != null) _buildMessageInput(),
        ],
      ),
    );
  }

  // Dropdown for admin to select a user to chat with
  Widget _buildUserSelector() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!.docs;

        return Padding(
          padding: AppPadding.content,
          child: DropdownButtonFormField<String>(
            value: selectedUserId,
            hint: const Text('Select a user'),
            items: users.map((doc) {
              final uid = doc.id;
              final name = doc['name'];
              return DropdownMenuItem(value: uid, child: Text(name));
            }).toList(),
            onChanged: (val) => setState(() => selectedUserId = val),
          ),
        );
      },
    );
  }

  // Chat input for user or admin
  Widget _buildMessageInput() {
    return Padding(
      padding: AppPadding.content,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // Send message to Firestore
  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    final chatData = {
      'uid': isAdmin ? selectedUserId : user.uid,
      'message': msg,
      'sender': isAdmin ? 'admin' : 'user',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('supportChats').add(chatData);

    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
