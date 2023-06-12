import "package:cloud_firestore/cloud_firestore.dart";
import "package:tuto/services/cloud/cloud_storage_constants.dart";

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String content;

  CloudNote(
      {required this.documentId,
      required this.ownerUserId,
      required this.content});

  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName],
        content = snapshot.data()[contentFieldName] as String;
}
