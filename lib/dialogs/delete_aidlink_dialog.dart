import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ignore: unused_import
import 'package:aidlinkapp/utilities/dependencies.dart';

class DeleteProgramDialog extends StatefulWidget {
  final String programId;
  final String programName;
  final Function onProgramDeleted;
  
  const DeleteProgramDialog({
    required this.programId,
    required this.programName,
    required this.onProgramDeleted,
    super.key,
  });

  @override
  State<DeleteProgramDialog> createState() => _DeleteProgramDialogState();
}

class _DeleteProgramDialogState extends State<DeleteProgramDialog> {
  RxString status = 'delete-program'.obs;

  Widget deleteProgramWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            'Delete "${widget.programName}"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
                onPressed: () {
                  status.value = 'deleting-program';
                },
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget deletingProgramWidget() {
    return FutureBuilder(
      future: _simulateProgramDeletion(), // Simulate API call
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Deleting Program...'),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          );
        } else if (snapshot.data == 'success') {
          Future.delayed(
            const Duration(seconds: 1),
            () {
              widget.onProgramDeleted();
              Navigator.pop(context);
            },
          );
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 50),
                SizedBox(height: 20),
                Text(
                  'Program Deleted Successfully!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 20),
                Text('Error: ${snapshot.data}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // Simulate program deletion (replace with actual API call later)
  Future<String> _simulateProgramDeletion() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate success (95% success rate for demo)
    return DateTime.now().millisecond % 20 == 0 ? 'Failed to delete program' : 'success';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: Obx(
          () => status.value == 'delete-program'
              ? deleteProgramWidget()
              : status.value == 'deleting-program'
                  ? deletingProgramWidget()
                  : const SizedBox(),
        ),
      ),
    );
  }
}