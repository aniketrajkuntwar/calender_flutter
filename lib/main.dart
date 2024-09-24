import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: MaterialApp(
        title: 'Calendar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CalendarTodoScreen(),
      ),
    );
  }
}

class CalendarTodoScreen extends StatefulWidget {
  const CalendarTodoScreen({super.key});

  @override
  _CalendarTodoScreenState createState() => _CalendarTodoScreenState();
}

class _CalendarTodoScreenState extends State<CalendarTodoScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: TodoListSection(
              selectedDay: _selectedDay ?? DateTime.now(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TodoProvider provider) {
    TextEditingController taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Enter task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  provider.addTask(
                      _selectedDay ?? DateTime.now(), taskController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class TodoListSection extends StatelessWidget {
  final DateTime selectedDay;

  const TodoListSection({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    final tasks = provider.getTasksForDay(selectedDay);

    return Column(
      children: [
        Text(
          'Tasks for ${selectedDay.toLocal()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: tasks.isNotEmpty
              ? ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(tasks[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          provider.removeTask(selectedDay, tasks[index]);
                        },
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text('No tasks for this day!'),
                ),
        ),
      ],
    );
  }
}

class TodoProvider extends ChangeNotifier {
  final Map<DateTime, List<String>> _todoList = {};

  UnmodifiableListView<String> getTasksForDay(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return UnmodifiableListView(_todoList[normalizedDate] ?? []);
  }

  void addTask(DateTime date, String task) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_todoList[normalizedDate] == null) {
      _todoList[normalizedDate] = [];
    }
    _todoList[normalizedDate]?.add(task);
    notifyListeners();
  }

  void removeTask(DateTime date, String task) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _todoList[normalizedDate]?.remove(task);
    if (_todoList[normalizedDate]?.isEmpty ?? false) {
      _todoList.remove(normalizedDate);
    }
    notifyListeners();
  }
}
