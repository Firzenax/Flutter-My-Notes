import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuto/services/CRUD/notes_service.dart';
import 'package:tuto/services/auth/auth_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textEditingController;

  Future<DatabaseNote> createNewNote() async {
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _notesService.getUser(email: email);
    return await _notesService.createNote(owner: owner);
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final content = _textEditingController.text;
    if (note != null && content.isNotEmpty) {
      await _notesService.updateNote(note: note, content: content);
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _notesService = NotesService();
    _textEditingController = TextEditingController();
    super.initState();
  }

  void _textEditingControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final content = _textEditingController.text;
    await _notesService.updateNote(note: note, content: content);
  }

  void _setupTextEditingControllerListener() {
    _textEditingController.removeListener(_textEditingControllerListener);
    _textEditingController.addListener(_textEditingControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New note")),
      body: FutureBuilder(
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _note = snapshot.data as DatabaseNote;
              _setupTextEditingControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration:
                    const InputDecoration(hintText: "Start typing your note"),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
