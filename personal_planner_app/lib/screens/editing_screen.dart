import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditingScreen extends StatefulWidget {
  final String shiftPlanId; // Document ID der Schicht

  const EditingScreen({super.key, required this.shiftPlanId});

  @override
  State<EditingScreen> createState() => _EditingScreenState();
}

class _EditingScreenState extends State<EditingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _shiftStart;
  DateTime? _shiftEnd;
  DateTime? _actualStart;
  DateTime? _actualEnd;
  Duration? _breakTime;

  final _shiftStartController = TextEditingController();
  final _shiftEndController = TextEditingController();
  final _actualStartController = TextEditingController();
  final _actualEndController = TextEditingController();
  final _breakTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShiftDetails();
  }

  Future<void> _loadShiftDetails() async {
    final doc = await _firestore
        .collection('dienstplans')
        .doc(widget.shiftPlanId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _shiftStart = data['shift_start'] != null
            ? (data['shift_start'] as Timestamp).toDate()
            : null;
        _shiftEnd = data['shift_end'] != null
            ? (data['shift_end'] as Timestamp).toDate()
            : null;
        _actualStart = data['actual_start'] != null
            ? (data['actual_start'] as Timestamp).toDate()
            : null;
        _actualEnd = data['actual_end'] != null
            ? (data['actual_end'] as Timestamp).toDate()
            : null;
        _breakTime = data['total_break_time'] != null
            ? Duration(minutes: data['total_break_time'])
            : null;

        _shiftStartController.text = _shiftStart != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_shiftStart!)
            : '';
        _shiftEndController.text = _shiftEnd != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_shiftEnd!)
            : '';
        _actualStartController.text = _actualStart != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_actualStart!)
            : '';
        _actualEndController.text = _actualEnd != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_actualEnd!)
            : '';
        _breakTimeController.text =
            _breakTime != null ? _breakTime!.inMinutes.toString() : '';
      });
    }
  }

  Future<void> _updateShiftDetails() async {
    await _firestore.collection('dienstplans').doc(widget.shiftPlanId).update({
      if (_shiftStart != null) 'shift_start': _shiftStart,
      if (_shiftEnd != null) 'shift_end': _shiftEnd,
      if (_actualStart != null) 'actual_start': _actualStart,
      if (_actualEnd != null) 'actual_end': _actualEnd,
      if (_breakTime != null) 'total_break_time': _breakTime!.inMinutes,
    });
    Navigator.of(context).pop();
  }

  Future<void> _selectDateTime(
      BuildContext context,
      TextEditingController controller,
      DateTime? initialDateTime,
      Function(DateTime) onSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
      );
      if (time != null) {
        final selectedDateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onSelected(selectedDateTime);
        controller.text =
            DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schicht bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateShiftDetails,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _shiftStartController,
                decoration:
                    const InputDecoration(labelText: 'Geplanter Schichtbeginn'),
                readOnly: true,
                onTap: () => _selectDateTime(
                  context,
                  _shiftStartController,
                  _shiftStart,
                  (selectedDate) => setState(() => _shiftStart = selectedDate),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _shiftEndController,
                decoration:
                    const InputDecoration(labelText: 'Geplantes Schichtende'),
                readOnly: true,
                onTap: () => _selectDateTime(
                  context,
                  _shiftEndController,
                  _shiftEnd,
                  (selectedDate) => setState(() => _shiftEnd = selectedDate),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _actualStartController,
                decoration:
                    const InputDecoration(labelText: 'Aktueller Schichtbeginn'),
                readOnly: true,
                onTap: () => _selectDateTime(
                  context,
                  _actualStartController,
                  _actualStart,
                  (selectedDate) => setState(() => _actualStart = selectedDate),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _actualEndController,
                decoration:
                    const InputDecoration(labelText: 'Aktuelles Schichtende'),
                readOnly: true,
                onTap: () => _selectDateTime(
                  context,
                  _actualEndController,
                  _actualEnd,
                  (selectedDate) => setState(() => _actualEnd = selectedDate),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _breakTimeController,
                decoration:
                    const InputDecoration(labelText: 'Pausenzeit (Minuten)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null) {
                    setState(() {
                      _breakTime = Duration(minutes: minutes);
                    });
                  } else {
                    setState(() {
                      _breakTime = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shiftStartController.dispose();
    _shiftEndController.dispose();
    _actualStartController.dispose();
    _actualEndController.dispose();
    _breakTimeController.dispose();
    super.dispose();
  }
}
