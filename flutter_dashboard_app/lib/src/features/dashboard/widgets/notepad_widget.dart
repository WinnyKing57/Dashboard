import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart'; // Will be created

class NotepadWidget extends StatefulWidget {
  final NotepadData notepadData;
  final String dashboardItemId; // To identify which DashboardItem this notepad belongs to

  const NotepadWidget({
    super.key,
    required this.notepadData,
    required this.dashboardItemId,
  });

  @override
  State<NotepadWidget> createState() => _NotepadWidgetState();
}

class _NotepadWidgetState extends State<NotepadWidget> {
  late TextEditingController _textController;
  final DashboardService _dashboardService = DashboardService(); // Instance of the service

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.notepadData.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    widget.notepadData.content = _textController.text;
    // We need a way to save this NotepadData instance.
    // If NotepadData is part of a DashboardItem, we might need to save the DashboardItem.
    // Or, if NotepadData has its own box or is managed directly by DashboardService.
    // For now, let's assume DashboardService has a method to update/save NotepadData
    // associated with a DashboardItem.
    await _dashboardService.updateNotepadData(widget.dashboardItemId, widget.notepadData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notepad', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.blueAccent),
                  onPressed: _saveNote,
                  tooltip: 'Save Note',
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Enter your notes here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null, // Allows for multi-line input
                expands: true, // Fills available vertical space
              ),
            ),
          ],
        ),
      ),
    );
  }
}
