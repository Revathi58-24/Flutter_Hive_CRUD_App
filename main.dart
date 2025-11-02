import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('studentsBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive CRUD (Web)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final studentsBox = Hive.box('studentsBox');
  int? editingKey; // to track if we are updating

  void _addOrUpdateStudent() {
    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim()) ?? 0;

    if (name.isEmpty) return;

    if (editingKey == null) {
      // Add new student
      studentsBox.add({'name': name, 'age': age});
    } else {
      // Update existing student
      studentsBox.put(editingKey, {'name': name, 'age': age});
      editingKey = null; // ✅ reset after update
    }

    // Clear input fields
    nameController.clear();
    ageController.clear();

    // Refresh UI to change button text
    setState(() {});
  }

  void _editStudent(int key, Map student) {
    nameController.text = student['name'];
    ageController.text = student['age'].toString();
    setState(() => editingKey = key);
  }

  void _deleteStudent(int key) {
    studentsBox.delete(key);
    if (editingKey == key) {
      nameController.clear();
      ageController.clear();
      setState(() => editingKey = null);
    }
  }

  void _clearAll() {
    studentsBox.clear();
    nameController.clear();
    ageController.clear();
    setState(() => editingKey = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive CRUD Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAll,
            tooltip: 'Clear All Students',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add / Edit Input Fields
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addOrUpdateStudent,
              icon: const Icon(Icons.save),
              label: Text(editingKey == null ? 'Add Student' : 'Update Student'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 15),

            // List of Students
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: studentsBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const Center(
                      child: Text('No Students Found'),
                    );
                  }

                  final keys = box.keys.toList();
                  return ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final key = keys[index];
                      final student = box.get(key);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(student['name']),
                          subtitle: Text('Age: ${student['age']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editStudent(key, student),
                              ),
                              IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteStudent(key),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
