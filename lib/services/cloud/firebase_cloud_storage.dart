import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuto/services/cloud/cloud_note.dart';
import 'package:tuto/services/cloud/cloud_storage_constants.dart';
import 'package:tuto/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection("notes");

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNotesException();
    }
  }

  Future<void> updateNote(
      {required String documentId, required String content}) async {
    try {
      notes.doc(documentId).update({contentFieldName: content});
    } catch (_) {
      throw CouldNotUpdateNotesException();
    }
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) =>
      notes.snapshots().map((event) => event.docs
          .map((doc) => CloudNote.fromSnapshot(doc))
          .where((note) => note.ownerUserId == ownerUserId));

  Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async {
    try {
      return await notes
          .where(
            ownerUserIdFieldName,
            isEqualTo: ownerUserId,
          )
          .get()
          .then(
              (value) => value.docs.map((doc) => CloudNote.fromSnapshot(doc)));
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerUserId,
      contentFieldName: "",
    });
    final fetchedNote = await document.get();
    return CloudNote(
        documentId: fetchedNote.id, ownerUserId: ownerUserId, content: "");
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage.sharedInstance();
  FirebaseCloudStorage.sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
