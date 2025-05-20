import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as GCalendar; // Import for GCalendar.Event
import '../theme.dart';
import 'components/const/colors.dart';
import 'components/button_widget.dart';
import 'calendar_page.dart';
import 'leaderboard_page.dart';
import 'settings_page.dart';
import 'avatar_design_page.dart';
import 'package:taskquest1/services/calendar_service.dart';
import '/services/task_repository.dart';
import 'chat_button.dart';

// final TaskRepository _taskRepo = TaskRepository();
// final String _userId = "yourUserId"; // Replace with real auth UID when ready

class TaskManagerPage extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;

  const TaskManagerPage({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _TaskManagerPageState createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> {
  final TaskRepository _taskRepo = TaskRepository();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final CalendarService _calendarService = CalendarService();

  List<Map<String, dynamic>> _tasks = []; // App's native tasks
  List<Map<String, dynamic>> _completedTasks = [];
  List<Map<String, dynamic>> _allCalendarDisplayTasks = []; // Combined list for calendar
  List<GCalendar.Event> _googleCalendarEvents = []; // Raw events from Google Calendar

  List<Map<String, dynamic>> _highPriorityTasks = [];
  List<Map<String, dynamic>> _mediumPriorityTasks = [];
  List<Map<String, dynamic>> _lowPriorityTasks = [];

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _taskNotesController = TextEditingController();

  // Avatar and points system
  final List<String> _avatarImages = [
    'assets/avatars/turtle.png',
    'assets/avatars/giraffe.png',
    'assets/avatars/Cat.png',
    'assets/avatars/dolphin.png',
    'assets/avatars/cow.png',
    'assets/avatars/panda.png',
    'assets/avatars/zebra.png',
  ];
  final List<bool> _unlockedAvatars = [true, true, true, false, false, false, false];
  final List<int> _unlockCosts = [0, 0, 0, 20, 50, 70, 100];
  String _currentAvatar = 'assets/avatars/turtle.png';
  int _userPoints = 0;

  String _sortOrder = 'Due Date';
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  String _selectedPriority = 'Medium';
  int? _editingIndex;
  double _progress = 0.0;
  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoadingCalendarEvents = false;

  @override
  void initState() {
    super.initState();
    _loadAppTasks(); // Renamed for clarity
    _fetchGoogleCalendarEventsForCurrentMonth();
    _calculateProgress();
  }

  Future<void> _loadAppTasks() async {
    if (!mounted) return;
    // Optionally show a loading indicator for app tasks
    try {
      final loadedTasks = await _taskRepo.loadTasks(_userId);
      if (mounted) {
        setState(() {
          _tasks = loadedTasks;
          _sortTasks(); // This will also call _groupTasksByPriority and _combineTasksForCalendarDisplay
        });
      }
    } catch (e) {
      print("Error loading app tasks from Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading your tasks: ${e.toString()}')),
        );
      }
    }
    // Now that app tasks are loaded (including their googleCalendarEventIds), fetch Google events
    // This ensures appTaskSyncedEventIds in _combineTasksForCalendarDisplay is correctly populated.
    _fetchGoogleCalendarEventsForCurrentMonth();
  }

  Future<void> _fetchGoogleCalendarEventsForCurrentMonth() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCalendarEvents = true;
    });

    try {
      final now = _focusedDay;
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0); // Day 0 of next month is last day of current

      final bool googleSignedIn = await _calendarService.isSignedIn();
      if (googleSignedIn) {
        final events = await _calendarService.getCalendarEventsList(
          startTime: firstDayOfMonth,
          endTime: lastDayOfMonth.add(Duration(days: 1)), // Ensure we capture events on the last day
        );
        if (mounted) {
          setState(() {
            _googleCalendarEvents = events;
            _combineTasksForCalendarDisplay();
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _googleCalendarEvents = []; // Clear if not signed in
            _combineTasksForCalendarDisplay();
          });
        }
      }
    } catch (e) {
      print("Error fetching Google Calendar events: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching Google Calendar events: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendarEvents = false;
        });
      }
    }
  }

  void _combineTasksForCalendarDisplay() {
    // Create a set of googleCalendarEventIds from app tasks for efficient lookup
    final Set<String> appTaskSyncedEventIds = _tasks
        .where((task) => task['googleCalendarEventId'] != null && (task['googleCalendarEventId'] as String).isNotEmpty)
        .map((task) => task['googleCalendarEventId'] as String)
        .toSet();

    // Transform app tasks
    final List<Map<String, dynamic>> formattedAppTasks = _tasks.map((task) {
      return {
        'id': task['id'].toString(),
        'task': task['task'],
        'dueDate': task['dueDate'],
        'priority': task['priority'] ?? 'Medium', // Default priority if null
        'isGoogleEvent': false,
        'notes': task['notes'],
      };
    }).toList();

    // Transform Google Calendar events, excluding those that are echoes of synced app tasks
    final List<Map<String, dynamic>> formattedGoogleEvents = _googleCalendarEvents
        .where((gEvent) => gEvent.id != null && !appTaskSyncedEventIds.contains(gEvent.id))
        .map((gEvent) {
      return {
        'id': gEvent.id!, // We've already checked gEvent.id != null in the where clause
        'task': gEvent.summary ?? 'Google Calendar Event',
        'dueDate': gEvent.start?.dateTime?.toLocal() ?? gEvent.start?.date?.toLocal() ?? DateTime.now(),
        'priority': 'Medium', // Google Calendar events don't have priority in our app's sense
        'isGoogleEvent': true,
        'notes': gEvent.description,
      };
    }).toList();

    setState(() {
      _allCalendarDisplayTasks = [...formattedAppTasks, ...formattedGoogleEvents];
      // Optional: Sort combined list if needed, e.g., by dueDate
      _allCalendarDisplayTasks.sort((a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Consider if re-fetching is needed more strategically
    // For example, when the app comes to the foreground or user explicitly refreshes
    _fetchGoogleCalendarEventsForCurrentMonth();
  }

  void _calculateProgress() {
    int completedCount = _completedTasks.length;
    int totalCount = _tasks.length + completedCount;
    setState(() {
      _progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    });
  }

  void _awardPoints(String priority) {
    int earnedPoints = switch (priority) {
      'High' => 10,
      'Medium' => 5,
      'Low' => 2,
      _ => 0,
    };
    _userPoints += earnedPoints;
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDueDate = picked);
  }

  Future<void> _pickDueTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? now,
    );
    if (picked != null) setState(() => _selectedDueTime = picked);
  }

  void _openTaskDialog({int? index}) {
    if (index != null) {
      _editingIndex = index;
      final task = _tasks[index];
      _taskController.text = task['task'];
      _taskNotesController.text = task['notes'] ?? '';
      final due = task['dueDate'] as DateTime;
      _selectedDueDate = DateTime(due.year, due.month, due.day);
      _selectedDueTime = TimeOfDay(hour: due.hour, minute: due.minute);
      _selectedPriority = task['priority'];
    } else {
      _editingIndex = null;
      _taskController.clear();
      _taskNotesController.clear();
      _selectedDueDate = null;
      _selectedDueTime = null;
      _selectedPriority = 'Medium';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_editingIndex == null ? 'Add Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: InputDecoration(labelText: 'Enter a task', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text(_selectedDueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${DateFormat('MMM dd, yyyy').format(_selectedDueDate!)}'),
                  trailing: Icon(Icons.calendar_today, color: primaryGreen),
                  onTap: _pickDueDate,
                ),
                ListTile(
                  title: Text(_selectedDueTime == null
                      ? 'Select Due Time'
                      : 'Time: ${_selectedDueTime!.format(context)}'),
                  trailing: Icon(Icons.access_time, color: primaryGreen),
                  onTap: _pickDueTime,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: ['High', 'Medium', 'Low']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPriority = v!),
                ),
                SizedBox(height: 12),
                ButtonWidget(
                  text: _editingIndex == null ? 'Add Task' : 'Update Task',
                  onPressed: _addOrEditTask,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _taskNotesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add any details...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addOrEditTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty || _selectedDueDate == null || _selectedDueTime == null)
      return;

    final dueDateTime = DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
      _selectedDueTime!.hour,
      _selectedDueTime!.minute,
    );

    // Prepare the base entry. For existing tasks, try to get existing googleCalendarEventId.
    String? existingGoogleCalendarEventId;
    if (_editingIndex != null) {
      existingGoogleCalendarEventId = _tasks[_editingIndex!]['googleCalendarEventId'] as String?;
    }

    final entry = {
      'id': _editingIndex != null ? _tasks[_editingIndex!]['id'] : DateTime
          .now()
          .millisecondsSinceEpoch,
      'task': text,
      'dueDate': dueDateTime,
      'priority': _selectedPriority,
      'completed': false,
      'notes': _taskNotesController.text.trim(),
      'googleCalendarEventId': existingGoogleCalendarEventId, // Use existing if editing, null if new
    };

    // Optimistic UI update: Add or update in the local _tasks list
    int taskIndexInUi = -1;
    if (_editingIndex != null) {
      taskIndexInUi = _editingIndex!;
      setState(() {
        _tasks[taskIndexInUi] = entry;
      });
    } else {
      setState(() {
        _tasks.add(entry);
        taskIndexInUi = _tasks.length - 1; // Index of the newly added task
      });
    }
    // Common UI updates after optimistic add/edit
    setState(() {
        _sortTasks();
        _groupTasksByPriority();
        _calculateProgress();
        // _combineTasksForCalendarDisplay(); // This will be called after potential GCal sync
    });

    try {
      bool googleSignedIn = await _calendarService.isSignedIn();
      String? eventIdFromGoogleSync = null;

      if (googleSignedIn) {
        if (entry['googleCalendarEventId'] == null) { // Only attempt to create if no existing GCal ID
          try {
            String? createdEventId = await _calendarService.createTaskEvent(
              title: entry['task'] as String,
              description: entry['notes'] as String?,
              startTime: entry['dueDate'] as DateTime,
              endTime: (entry['dueDate'] as DateTime).add(const Duration(hours: 1)),
            );
            if (createdEventId != null) {
              eventIdFromGoogleSync = createdEventId;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task synced to Google Calendar.')),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not sync task to Google Calendar.')),
              );
            }
          } catch (e) {
            print('Error syncing task to Google Calendar: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error syncing to Google Calendar: ${e.toString()}')),
              );
            }
          }
        }
      }

      // Update the entry map with the Google Calendar Event ID if it was obtained
      if (eventIdFromGoogleSync != null) {
        entry['googleCalendarEventId'] = eventIdFromGoogleSync;
        // Also update the specific task in the local _tasks list if it's a new task that just got synced
        if (_editingIndex == null && taskIndexInUi != -1 && taskIndexInUi < _tasks.length) {
            setState(() {
                _tasks[taskIndexInUi]['googleCalendarEventId'] = eventIdFromGoogleSync;
            });
        }
      }

      await _taskRepo.saveTask(_userId, entry); // Save task to Firestore

    } catch (e) {
      print("Error during task save or Google Sync: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: ${e.toString()}')),
        );
      }
      // Minimal revert: if it was a new add, remove it from UI. Editing is harder to revert cleanly here.
      if (_editingIndex == null && taskIndexInUi != -1) {
          setState(() {
              _tasks.removeAt(taskIndexInUi);
              _sortTasks();
              _groupTasksByPriority();
              _calculateProgress();
          });
      }
      // Do not pop dialog if save failed
      if (mounted) _combineTasksForCalendarDisplay(); // Refresh display even on error
      return;
    }
    
    // If all successful
    if (mounted) {
        _combineTasksForCalendarDisplay(); // Crucial: refresh display after all ops
        Navigator.pop(context); // Pop dialog
    }
  }

  void _toggleTaskCompletion(int index) async {
    setState(() {
      final task = _tasks.removeAt(index);
      task['completed'] = true;
      task['completedDate'] = DateTime.now();
      _completedTasks.add(task);
      _awardPoints(task['priority']);
      _calculateProgress();
    });

    // Save updated task
    await _taskRepo.saveTask(_userId, _completedTasks.last);

    // 🔥 Update points in Firestore
    int earnedPoints = switch (_completedTasks.last['priority']) {
      'High' => 10,
      'Medium' => 5,
      'Low' => 2,
      _ => 0,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .update({
      'points': FieldValue.increment(earnedPoints),
    });
  }


  void _unmarkTask(int index) {
    setState(() {
      final task = _completedTasks.removeAt(index);
      task['completed'] = false;
      _tasks.add(task);
      _sortTasks();
      _groupTasksByPriority();
      _calculateProgress();
    });
  }

  void _deleteTask(int index) async { // Make async
    if (index < 0 || index >= _tasks.length) return;

    final taskToDelete = _tasks[index];
    final String taskId = taskToDelete['id'].toString();
    final String? googleEventId = taskToDelete['googleCalendarEventId'] as String?;

    // Optimistically remove from UI first
    setState(() {
      _tasks.removeAt(index);
      _groupTasksByPriority();
      _calculateProgress();
      _combineTasksForCalendarDisplay(); 
    });

    try {
      // Delete from Firestore
      await _taskRepo.deleteTask(_userId, taskId);

      // Delete from Google Calendar if an event ID exists
      if (googleEventId != null && googleEventId.isNotEmpty) {
        bool googleSignedIn = await _calendarService.isSignedIn();
        if (googleSignedIn) {
          await _calendarService.deleteTaskEvent(eventId: googleEventId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task deleted from Google Calendar.')),
            );
          }
        } else {
          // If not signed into Google, the event remains but will be out of sync.
          // Optionally inform user or log.
          print('Not signed into Google. Could not delete event from Google Calendar.');
        }
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task deleted successfully.')),
          );
      }
    } catch (e) {
      print("Error deleting task: $e");
      // If deletion fails, we should ideally add the task back to the UI
      // For simplicity, current optimistic UI update is not reverted here.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: ${e.toString()}')),
        );
         // Add task back to UI if deletion failed
        setState(() {
            _tasks.insert(index, taskToDelete);
            _sortTasks(); // resort because insert might break order
            _groupTasksByPriority();
            _calculateProgress();
            _combineTasksForCalendarDisplay(); 
        });
      }
    }
  }

  void _sortTasks() {
    if (_sortOrder == 'Due Date') {
      _tasks.sort((a, b) => a['dueDate'].compareTo(b['dueDate']));
    } else {
      _tasks.sort((a, b) => b['id'].compareTo(a['id']));
    }
    _combineTasksForCalendarDisplay(); // Re-combine after sorting app tasks
  }

  void _groupTasksByPriority() {
    _highPriorityTasks = _tasks.where((t) => t['priority'] == 'High').toList();
    _mediumPriorityTasks = _tasks.where((t) => t['priority'] == 'Medium').toList();
    _lowPriorityTasks = _tasks.where((t) => t['priority'] == 'Low').toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPrioritySection(String title, Color color, List<Map<String, dynamic>> tasks) {
    final filtered = tasks.where((task) => !task['completed']).toList();
    if (filtered.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          ...filtered.map((task) => _buildTaskCard(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final int index = _tasks.indexOf(task);
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getPriorityColor(task['priority']),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(task['task']),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due: ${DateFormat('MMM dd, yyyy').format(task['dueDate'])}'),
            if (task['notes']?.isNotEmpty ?? false) Text('Notes: ${task['notes']}'),
          ],
        ),
        leading: Checkbox(
          value: task['completed'],
          onChanged: (_) => _toggleTaskCompletion(index),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit, color: Colors.green), onPressed: () => _openTaskDialog(index: index)),
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTask(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 6),
              Text('Points: $_userPoints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 20,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[300]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text('Progress: ${(_progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 1:
        return _buildCalendarPage();
      case 2:
        return _buildCompletedTasksList();
      case 3:
        return LeaderboardPage();
      case 4:
        return SettingsPage(
          currentTheme: widget.currentTheme,
          onThemeChanged: widget.onThemeChanged,
        );
      default:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButton<String>(
                value: _sortOrder,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                    _sortTasks();
                    _groupTasksByPriority();
                  });
                },
                items: ['Due Date', 'Recently Added']
                    .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
              ),
            ),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPrioritySection('PRIORITY: HIGH', Colors.red, _highPriorityTasks),
                    _buildPrioritySection('PRIORITY: MEDIUM', Colors.orange, _mediumPriorityTasks),
                    _buildPrioritySection('PRIORITY: LOW', Colors.green, _lowPriorityTasks),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCalendarPage() {
    return Column(
      children: [
        if (_isLoadingCalendarEvents) Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        Expanded(
          child: CalendarPage(
            tasks: _allCalendarDisplayTasks, // Pass the combined list
            selectedDay: _selectedDay,
            focusedDay: _focusedDay,
            onDaySelected: (selected, focused) {
              bool needsRefresh = false;
              if (focused.month != _focusedDay.month || focused.year != _focusedDay.year) {
                needsRefresh = true;
              }
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              if (needsRefresh) {
                _fetchGoogleCalendarEventsForCurrentMonth();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTasksList() {
    _completedTasks.sort((a, b) => b['completedDate'].compareTo(a['completedDate']));
    return _completedTasks.isEmpty
        ? Center(child: Text('No completed tasks yet.'))
        : ListView.builder(
      itemCount: _completedTasks.length,
      itemBuilder: (context, index) {
        final task = _completedTasks[index];
        return Card(
          child: ListTile(
            title: Text(task['task']),
            subtitle: Text(
              'Completed on: ${DateFormat('MMM dd, yyyy').format(task['completedDate'])}',
              style: const TextStyle(fontSize: 14),
            ),
            leading: Icon(Icons.check_circle, color: Colors.green),
            trailing: IconButton(
              icon: Icon(Icons.undo, color: Colors.blue),
              onPressed: () => _unmarkTask(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBarItemIcon(int index, IconData iconData) {
    bool isSelected = _currentIndex == index;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(iconData, color: isSelected ? Colors.white : primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () async {
            final selectedIndex = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => AvatarDesignPage(
                  avatarImages: _avatarImages,
                  unlockedAvatars: _unlockedAvatars,
                  unlockCosts: _unlockCosts,
                  userPoints: _userPoints,
                ),
              ),
            );
            if (selectedIndex != null) {
              setState(() {
                if (!_unlockedAvatars[selectedIndex]) {
                  _unlockedAvatars[selectedIndex] = true;
                  _userPoints -= _unlockCosts[selectedIndex];
                }
                _currentAvatar = _avatarImages[selectedIndex];
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(_currentAvatar),
            ),
          ),
        ),
      ),
      body: _buildTabContent(_currentIndex),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1 // Allow adding tasks from home or calendar view
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_task',
            backgroundColor: primaryGreen,
            child: Icon(Icons.add, color: Colors.white),
            onPressed: () => _openTaskDialog(),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'chat_assistant',
            backgroundColor: Colors.white,
            child: Icon(Icons.chat_bubble_outline, color: primaryGreen),
            onPressed: () => showTaskAssistant(context), // Make sure this function is defined
          ),
        ],
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: _buildNavBarItemIcon(0, Icons.home), label: ''),
          BottomNavigationBarItem(icon: _buildNavBarItemIcon(1, Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: _buildNavBarItemIcon(2, Icons.check_circle), label: ''),
          BottomNavigationBarItem(icon: _buildNavBarItemIcon(3, Icons.leaderboard), label: ''),
          BottomNavigationBarItem(icon: _buildNavBarItemIcon(4, Icons.settings), label: ''),
        ],
      ),
    );
  }
}
