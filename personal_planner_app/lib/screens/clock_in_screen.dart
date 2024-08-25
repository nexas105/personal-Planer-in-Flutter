import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ClockInScreen extends StatefulWidget {
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final String shiftPlanId;

  const ClockInScreen({
    super.key,
    required this.shiftStart,
    required this.shiftEnd,
    required this.shiftPlanId,
  });

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _shiftStarted = false;
  bool _onBreak = false;
  DateTime? _actualStart;
  DateTime? _pauseStart;
  Duration _totalBreakTime = Duration.zero;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _startInitialTimer();
  }

  void _startInitialTimer() {
    _remainingTime = widget.shiftStart.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
          if (_remainingTime.isNegative) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _startShift() {
    setState(() {
      _shiftStarted = true;
      _actualStart = DateTime.now();
      _startShiftTimer();
    });
  }

  void _startShiftTimer() {
    _remainingTime = widget.shiftEnd.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
          if (_remainingTime.isNegative) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _pauseShift() {
    setState(() {
      _onBreak = !_onBreak;
      if (_onBreak) {
        _pauseStart = DateTime.now();
        _timer?.cancel();
      } else {
        if (_pauseStart != null) {
          _totalBreakTime += DateTime.now().difference(_pauseStart!);
        }
        _startShiftTimer();
      }
    });
  }

  void _endShift() async {
    _timer?.cancel();
    final endTime = DateTime.now();

    bool confirmEnd = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schicht beenden'),
        content: const Text('Möchtest du die Schicht wirklich beenden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );

    if (confirmEnd) {
      // Speichern der Schichtdaten in der Datenbank
      await _firestore
          .collection('dienstplans')
          .doc(widget.shiftPlanId)
          .update({
        'actual_start': _actualStart,
        'actual_end': endTime,
        'total_break_time': _totalBreakTime.inMinutes,
        'complete': true,
      });

      if (mounted) {
        Navigator.of(context).pop(); // Zurück zur Startseite
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canStartShift =
        now.isAfter(widget.shiftStart.subtract(const Duration(minutes: 15))) &&
            !_shiftStarted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schicht'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_shiftStarted)
              Text(
                'Schicht beginnt in: ${_remainingTime.isNegative ? "Jetzt" : _remainingTime.toString().split('.').first}',
                style: const TextStyle(fontSize: 24),
              ),
            if (_shiftStarted)
              Text(
                'Schicht endet in: ${_remainingTime.isNegative ? "Beendet" : _remainingTime.toString().split('.').first}',
                style: const TextStyle(fontSize: 24),
              ),
            const SizedBox(height: 20),
            if (canStartShift && !_shiftStarted)
              ElevatedButton(
                onPressed: _startShift,
                child: const Text('Schicht starten'),
              ),
            if (_shiftStarted)
              ElevatedButton(
                onPressed: _pauseShift,
                child: Text(_onBreak ? 'Weiterarbeiten' : 'Pause'),
              ),
            if (_shiftStarted && !_onBreak)
              ElevatedButton(
                onPressed: _endShift,
                child: const Text('Schicht beenden'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
