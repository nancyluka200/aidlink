import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AddProgramDialog extends StatefulWidget {
  final Function onProgramAdded;
  
  const AddProgramDialog({
    required this.onProgramAdded,
    super.key,
  });

  @override
  State<AddProgramDialog> createState() => _AddProgramDialogState();
}

class _AddProgramDialogState extends State<AddProgramDialog> {
  RxString status = 'select-category'.obs;
  final programNameController = TextEditingController();
  final programDescriptionController = TextEditingController();
  String selectedCategory = 'Education';

  // Categories for AidLink programs
  final List<String> categories = [
    'Education',
    'Food Relief',
    'Healthcare',
    'Housing',
    'Employment',
    'Disability',
    'Youth',
    'Elderly',
    'Family'
  ];

  Widget selectCategoryWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select Program Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const Text('Next'),
                onPressed: () {
                  status.value = 'add-details';
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

  Widget addDetailsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Add Program Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: programNameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: programDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Category: $selectedCategory',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: const Text('Save Program'),
                  onPressed: () {
                    if (programNameController.text.isNotEmpty &&
                        programDescriptionController.text.isNotEmpty) {
                      status.value = 'saving-program';
                    } else {
                      Get.snackbar(
                        'Error',
                        'Please fill all fields',
                        backgroundColor: const Color.fromARGB(255, 239, 133, 125),
                        colorText: Colors.white,
                      );
                    }
                  },
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  child: const Text('Back'),
                  onPressed: () {
                    status.value = 'select-category';
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget savingProgramWidget() {
    return FutureBuilder(
      future: _simulateProgramSave(), // Simulate API call
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Saving Program...'),
                SizedBox(height: 20),
                CircularProgressIndicator(), // Fixed: capital C
              ],
            ),
          );
        } else if (snapshot.data == 'success') {
          Future.delayed(
            const Duration(seconds: 1),
            () {
              widget.onProgramAdded();
              Navigator.pop(context); //  Fixed: Navigator.app → Navigator.pop
            },
          );
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color.fromARGB(255, 90, 126, 92), size: 50),
                SizedBox(height: 20),
                Text(
                  'Program Added Successfully!',
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

  
  Future<String> _simulateProgramSave() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate success 
    return DateTime.now().millisecond % 10 == 0 ? 'Failed to save program' : 'success';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Obx(
          () => status.value == 'select-category'
              ? selectCategoryWidget()
              : status.value == 'add-details'
                  ? addDetailsWidget()
                  : status.value == 'saving-program'
                      ? savingProgramWidget()
                      : const SizedBox(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    programNameController.dispose();
    programDescriptionController.dispose();
    super.dispose();
  }
}