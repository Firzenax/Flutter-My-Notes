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
          .then((value) => value.docs.map((doc) {
                return CloudNote(
                    documentId: doc.id,
                    ownerUserId: doc.data()[ownerUserIdFieldName],
                    content: doc.data()[contentFieldName]);
              }));
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  void createNewNote({required String ownerUserId}) async {
    notes.add({
      ownerUserIdFieldName: ownerUserId,
      contentFieldName: "",
    });
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage.sharedInstance();
  FirebaseCloudStorage.sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
