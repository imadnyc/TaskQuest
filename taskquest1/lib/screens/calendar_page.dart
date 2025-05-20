import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'components/const/colors.dart';

class CalendarPage extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final DateTime? selectedDay;
  final DateTime focusedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const CalendarPage({
    Key? key,
    required this.tasks,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
  }) : super(key: key);

  Color _getEventColor(Map<String, dynamic> event) {
    if (event['isGoogleEvent'] == true) {
      return Colors.blue.shade700; // Distinct color for Google Calendar events
    }
    switch (event['priority']) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          onDaySelected: onDaySelected,
          eventLoader: (day) {
            return tasks.where((task) {
              final taskDate = task['dueDate'];
              return taskDate != null && isSameDay(taskDate, day);
            }).toList();
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                // Use the color from the first event for the marker
                final eventData = events.first as Map<String, dynamic>; 
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getEventColor(eventData),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.green[900],
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          calendarFormat: CalendarFormat.month,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: tasks
                .where((task) =>
                    task['dueDate'] != null &&
                    selectedDay != null &&
                    isSameDay(task['dueDate'], selectedDay))
                .map((task) => Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: _getEventColor(task), // Use updated color logic for list items
                            width: 10,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['task'],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          if (task['dueDate'] != null) 
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy hh:mm a').format(task['dueDate'].toLocal())}', // More specific time
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          if (task['isGoogleEvent'] == true && task['notes'] != null && task['notes'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Notes: ${task['notes']}',
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else if (task['isGoogleEvent'] != true && task['notes'] != null && task['notes'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Text('🗒️', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      task['notes'],
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
