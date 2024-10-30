import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TaskController extends GetxController {
  static TaskController get to => Get.find();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList tasks = [].obs;

  // Collection reference
  late final CollectionReference _tasksCollection;

  @override
  void onInit() {
    super.onInit();
    _tasksCollection = _firestore.collection('tasks');
    ever(error, (String message) {
      if (message.isNotEmpty) {
        _showErrorSnackbar(message);
      }
    });
  }

  // Get stream of tasks for current user
  Stream<QuerySnapshot> get tasksStream => _tasksCollection
      .where('userId', isEqualTo: _auth.currentUser?.uid)
      .orderBy('date', descending: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((e) {
    error.value = 'Error fetching tasks: ${e.toString()}';
  });

  // Create new task
  Future<bool> createTask(String nama, String deskription, DateTime date) async {
    if (!_validateInput(nama, deskription)) return false;

    try {
      isLoading.value = true;
      error.value = '';

      final userId = _getCurrentUserId();
      if (userId == null) return false;

      await _tasksCollection.add({
        'nama': nama.trim(),
        'deskription': deskription.trim(),
        'date': date,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      _showSuccessSnackbar('Task berhasil dibuat');
      return true;
    } catch (e) {
      error.value = 'Error creating task: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing task
  Future<bool> updateTask(String documentId, String nama, String deskription, DateTime date) async {
    if (!_validateInput(nama, deskription)) return false;

    try {
      isLoading.value = true;
      error.value = '';

      final userId = _getCurrentUserId();
      if (userId == null) return false;

      // Verify task ownership before updating
      final docSnapshot = await _tasksCollection.doc(documentId).get();
      if (!docSnapshot.exists || docSnapshot.get('userId') != userId) {
        error.value = 'Task tidak ditemukan atau Anda tidak memiliki akses';
        return false;
      }

      await _tasksCollection.doc(documentId).update({
        'nama': nama.trim(),
        'deskription': deskription.trim(),
        'date': date,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('Task berhasil diperbarui');
      return true;
    } catch (e) {
      error.value = 'Error updating task: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String documentId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _getCurrentUserId();
      if (userId == null) return false;

      // Verify task ownership before deleting
      final docSnapshot = await _tasksCollection.doc(documentId).get();
      if (!docSnapshot.exists || docSnapshot.get('userId') != userId) {
        error.value = 'Task tidak ditemukan atau Anda tidak memiliki akses';
        return false;
      }

      await _tasksCollection.doc(documentId).delete();
      _showSuccessSnackbar('Task berhasil dihapus');
      return true;
    } catch (e) {
      error.value = 'Error deleting task: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String documentId, String status) async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _getCurrentUserId();
      if (userId == null) return false;

      await _tasksCollection.doc(documentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('Status task berhasil diperbarui');
      return true;
    } catch (e) {
      error.value = 'Error updating task status: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  String? _getCurrentUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      error.value = 'User tidak terautentikasi';
      return null;
    }
    return userId;
  }

  bool _validateInput(String nama, String deskription) {
    if (nama.trim().isEmpty) {
      error.value = 'Nama task tidak boleh kosong';
      return false;
    }
    if (deskription.trim().isEmpty) {
      error.value = 'Deskripsi tidak boleh kosong';
      return false;
    }
    return true;
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Sukses',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }

  SingOut() {}
}