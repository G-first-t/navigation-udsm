import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    await FirebaseFirestore.instance.collection('feedback').add({
      'message': message,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback submitted. Thank you!")),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Feedback", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "If a location wasn't found or you faced an issue, let us know:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Describe the issue...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text("Submit",style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
