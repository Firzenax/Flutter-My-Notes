import "dart:async";

import "package:flutter/foundation.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart"
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import "package:path/path.dart" show join;
import "package:tuto/services/crud/crud_exceptions.dart";

class NotesService {
  Database? _db;

  List<DatabaseNote> _notes = [];

  static final NotesService _shared = NotesService._sharedInstance();

  NotesService._sharedInstance();

  factory NotesService() => _shared;

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String content}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.id);

    final updateCount = await db.update(
        noteTable, {contentColumn: content, isSynchedWithCloudColumn: 0});

    if (updateCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((n) => DatabaseNote.fromRow(notes.first));
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes =
        await db.query(noteTable, limit: 1, where: 'id = ?', whereArgs: [id]);

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final numberOfDeletion = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);

    return numberOfDeletion;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount =
        await db.delete(noteTable, where: 'id = ?', whereArgs: [id]);
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    //? Try to connect to the Database
    final db = _getDatabaseOrThrow();
    //? Make sure the owner exists in the database
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }
    const content = '';
    //? Create the note
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      contentColumn: content,
      isSynchedWithCloudColumn: 1
    });

    final note = DatabaseNote(
        id: noteId,
        userId: owner.id,
        content: content,
        isSynchedWithCloud: true);

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable,
        limit: 1, where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result = await db.query(userTable,
        limit: 1, where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (result.isNotEmpty) {
      throw UserAlreadyExist();
    }

    final userId =
        await db.insert(userTable, {emailColumn: email.toLowerCase()});

    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deleteCount = await db.delete(
      userTable,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );
    if (deleteCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpened();
    } else {
      return db;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {}
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpened();
    } else {
      db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbname);
      final db = await openDatabase(dbPath);
      _db = db;
      // create the user table
      await db.execute(createUserTable);
      // create note table
      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
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

  DatabaseNote(
      {required this.id,
      required this.userId,
      required this.content,
      required this.isSynchedWithCloud});

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        content = map[contentColumn] as String,
        isSynchedWithCloud =
            (map[isSynchedWithCloudColumn] as int) == 1 ? true : false;

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
const isSynchedWithCloudColumn = "is_synched_with_cloud";

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
