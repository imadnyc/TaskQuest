import 'package:cloud_firestore/cloud_firestore.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTask(String userId, Map<String, dynamic> task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task['id'].toString())
        .set(task);
  }

  Future<List<Map<String, dynamic>>> loadTasks(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Convert Firestore Timestamp to DateTime
      if (data['dueDate'] is Timestamp) {
        data['dueDate'] = (data['dueDate'] as Timestamp).toDate();
      } else if (data['dueDate'] is String) {
        // Fallback for older data that might have been stored as string (less likely now)
        data['dueDate'] = DateTime.parse(data['dueDate'] as String);
      }
      // Ensure completedDate is also handled if it exists and is a Timestamp
      if (data['completedDate'] != null && data['completedDate'] is Timestamp) {
        data['completedDate'] = (data['completedDate'] as Timestamp).toDate();
      } else if (data['completedDate'] != null && data['completedDate'] is String) {
        data['completedDate'] = DateTime.parse(data['completedDate'] as String);
      }
      return data;
    }).toList();
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
