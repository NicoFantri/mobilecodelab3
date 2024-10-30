import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:codelab3/app/modules/utils/app_color.dart';
import 'package:codelab3/app/modules/screens/widget_background.dart';
import '../home/controllers/task_controller.dart';

class CreateTaskScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? task;
  final String? documentId;

  CreateTaskScreen({
    required this.isEdit,
    this.task,
    this.documentId,
  });

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskriptionController = TextEditingController();
  final TaskController taskController = Get.find<TaskController>();
  final AppColor appColor = AppColor();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      _namaController.text = widget.task!['nama'] ?? '';
      _deskriptionController.text = widget.task!['deskription'] ?? '';

      if (widget.task!['date'] != null) {
        try {
          _selectedDate = (widget.task!['date'] as Timestamp).toDate();
        } catch (e) {
          print('Error parsing date: $e');
          _selectedDate = DateTime.now();
        }
      }
    }
  }

  String _formatMonthToIndonesian(DateTime date) {
    const months = {
      1: 'Januari',
      2: 'Februari',
      3: 'Maret',
      4: 'April',
      5: 'Mei',
      6: 'Juni',
      7: 'Juli',
      8: 'Agustus',
      9: 'September',
      10: 'Oktober',
      11: 'November',
      12: 'Desember'
    };
    return months[date.month] ?? '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        bool success;

        if (widget.isEdit && widget.documentId != null) {
          success = await taskController.updateTask(
            widget.documentId!,
            _namaController.text,
            _deskriptionController.text,
            _selectedDate,
          );
        } else {
          success = await taskController.createTask(
            _namaController.text,
            _deskriptionController.text,
            _selectedDate,
          );
        }

        if (success) {
          Get.back(result: true); // Kembali ke layar utama setelah sukses
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Terjadi kesalahan: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor.colorPrimary,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Task' : 'Buat Task Baru'),
        backgroundColor: appColor.colorTertiary,
      ),
      body: Stack(
        children: [
          WidgetBackground(),
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nama Task Field
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Task',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama task tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),

                  // Deskripsi Field
                  TextFormField(
                    controller: _deskriptionController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),

                  // Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day} ${_formatMonthToIndonesian(_selectedDate)} ${_selectedDate.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32.0),

                  // Submit Button
                  Obx(() => ElevatedButton(
                    onPressed: taskController.isLoading.value ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor.colorTertiary,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: taskController.isLoading.value
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      widget.isEdit ? 'Perbarui Task' : 'Buat Task',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskriptionController.dispose();
    super.dispose();
  }
}
