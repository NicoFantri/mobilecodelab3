import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:codelab3/app/modules/utils/app_color.dart';
import 'package:codelab3/app/modules/screens/create_task_screen.dart';
import 'package:codelab3/app/modules/screens/widget_background.dart';
import '../home/controllers/task_controller.dart';

class HomeScreen extends GetView<TaskController> {
  final AppColor _appColor = AppColor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appColor.colorPrimary,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          WidgetBackground(),
          _buildTasksList(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Task Manager'),
      backgroundColor: _appColor.colorTertiary,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await controller.SingOut();
            Get.offAllNamed('/login'); // Navigate to login after logout
          },
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.tasksStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada task. Tambahkan task baru!',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildTaskCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(String docId, Map<String, dynamic> data) {
    final DateTime date = (data['date'] as Timestamp).toDate();
    final String formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTaskOptions(docId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['nama'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(data['status'] ?? 'pending'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['deskription'] ?? '',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTask(docId, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(docId),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        statusText = 'Dalam Proses';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Pending';
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  FloatingActionButton _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _createNewTask(),
      backgroundColor: _appColor.colorTertiary,
      child: const Icon(Icons.add),
    );
  }

  void _createNewTask() async {
    final result = await Get.to(() => CreateTaskScreen(isEdit: false));

    if (result == true) {
      Get.snackbar(
        'Sukses',
        'Task berhasil dibuat',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _editTask(String docId, Map<String, dynamic> data) async {
    final result = await Get.to(() => CreateTaskScreen(
      isEdit: true,
      documentId: docId,
      task: data,
    ));

    if (result == true) {
      Get.snackbar(
        'Sukses',
        'Task berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteTask(String docId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus task ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await controller.deleteTask(docId);
      if (success) {
        Get.snackbar(
          'Sukses',
          'Task berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _openTaskOptions(String docId, Map<String, dynamic> data) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Tandai Selesai'),
              onTap: () async {
                Get.back();
                await controller.updateTaskStatus(docId, 'completed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Tandai Dalam Proses'),
              onTap: () async {
                Get.back();
                await controller.updateTaskStatus(docId, 'in_progress');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Task'),
              onTap: () {
                Get.back();
                _editTask(docId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Task', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _deleteTask(docId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
