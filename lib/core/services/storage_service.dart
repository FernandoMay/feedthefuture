import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feed_the_future/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<Either<AppFailure, String>> uploadImage({
    required File imageFile,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, void>> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
