import "package:flutter/foundation.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart"
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import "package:path/path.dart" show join;

class DatabaseAlreadyOpenException implements Exception {}

class UnableToGetDocumentDirectory implements Exception {}

class DatabaseIsNotOpened implements Exception {}

class NotesService {
  Database? _db;

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbname);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);
      await db.execute(createNoteTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }

  Future<void> close() async {}
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id , email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String content;
  final bool isSynchedWithCloud;

  DatabaseNote(this.id, this.userId, this.content, this.isSynchedWithCloud);

  DatabaseNote.fromRow(Map<String, Object> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        content = map[contentColumn] as String,
        isSynchedWithCloud =
            (map[isSynchedWithCloudMap] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id , user_id = $userId, content = $content, synched : $isSynchedWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

//? Database info section

const dbname = "notes.db";
const noteTable = "note";
const userTable = "user";

//? Column section

const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const contentColumn = "content";
const isSynchedWithCloudMap = "is_synched_with_cloud";

//? Table creation section

const createUserTable = '''
  CREATE TABLE IF NOT EXISTS "user" (
    "id"	INTEGER NOT NULL,
    "email"	TEXT NOT NULL UNIQUE,
  PRIMARY KEY("id" AUTOINCREMENT)
  );
''';
const createNoteTable = '''
  CREATE TABLE "notes" (
    "id"	INTEGER NOT NULL,
    "user_id"	INTEGER NOT NULL,
    "content"	TEXT NOT NULL,
    "is_synched_with_cloud"	INTEGER DEFAULT 0,
    PRIMARY KEY("id" AUTOINCREMENT),
    FOREIGN KEY("user_id") REFERENCES "user"("id")
  );
''';
