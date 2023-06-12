import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuto/services/auth/auth_service.dart';
import 'package:tuto/utilities/dialogs/cannot_share_empty_note.dart';
import 'package:tuto/utilities/generics/get_arguments.dart';
import "package:tuto/services/cloud/cloud_note.dart";
import "package:tuto/services/cloud/firebase_cloud_storage.dart";

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textEditingController;

  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _textEditingController.text = widgetNote.content;
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newNote = await _notesService.createNewNote(ownerUserId: userId);
    _note = newNote;
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(documentId: note.documentId);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final content = _textEditingController.text;
    if (note != null && content.isNotEmpty) {
      await _notesService.updateNote(
          documentId: note.documentId, content: content);
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
    _notesService = FirebaseCloudStorage();
    _textEditingController = TextEditingController();
    super.initState();
  }

  void _textEditingControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final content = _textEditingController.text;
    await _notesService.updateNote(
        documentId: note.documentId, content: content);
  }

  void _setupTextEditingControllerListener() {
    _textEditingController.removeListener(_textEditingControllerListener);
    _textEditingController.addListener(_textEditingControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New note"),
        actions: [
          IconButton(
              onPressed: () async {
                final content = _textEditingController.text;
                if (_note == null && content.isEmpty) {
                  await showCannotShareEmptyNoteDialog(context);
                } else {
                  Share.share(content);
                }
              },
              icon: const Icon(Icons.share))
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
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
