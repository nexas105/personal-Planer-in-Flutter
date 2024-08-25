import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_planner_app/screens/clock_in_screen.dart';
import 'package:personal_planner_app/screens/editing_screen.dart';
import 'package:personal_planner_app/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Stream<QuerySnapshot> _getUserShiftPlans() {
    final userId = _auth.currentUser?.uid;
    final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);

    return _firestore
        .collection('dienstplans')
        .where('userid', isEqualTo: userId)
        .where('shift_start', isGreaterThanOrEqualTo: startOfMonth)
        .where('shift_start', isLessThanOrEqualTo: endOfMonth)
        .orderBy('shift_start', descending: false)
        .snapshots();
  }

  String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                          DateFormat.MMMM().format(DateTime(0, index + 1))),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                  },
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(10, (index) {
                    final year = DateTime.now().year - 5 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshShiftPlans,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUserShiftPlans(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Keine Dienstpläne verfügbar.'));
                  }

                  final dienstplaene = snapshot.data!.docs;
                  int plannedMinutes = 0;
                  int workedMinutes = 0;

                  for (var doc in dienstplaene) {
                    final dienstplan = doc.data() as Map<String, dynamic>;
                    final shiftStart =
                        (dienstplan['shift_start'] as Timestamp).toDate();
                    final shiftEnd =
                        (dienstplan['shift_end'] as Timestamp).toDate();
                    final complete = dienstplan['complete'] as bool;
                    final breakTime =
                        dienstplan['total_break_time'] as int? ?? 0;

                    final shiftDuration =
                        shiftEnd.difference(shiftStart).inMinutes;

                    if (complete) {
                      final actualStart =
                          (dienstplan['actual_start'] as Timestamp?)
                                  ?.toDate() ??
                              shiftStart;
                      final actualEnd =
                          (dienstplan['actual_end'] as Timestamp?)?.toDate() ??
                              shiftEnd;
                      final actualDuration =
                          actualEnd.difference(actualStart).inMinutes;
                      workedMinutes += (actualDuration - breakTime);
                    } else {
                      plannedMinutes += shiftDuration;
                    }
                  }

                  final now = DateTime.now();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: dienstplaene.length,
                          itemBuilder: (context, index) {
                            final dienstplanDoc = dienstplaene[index];
                            final dienstplan =
                                dienstplanDoc.data() as Map<String, dynamic>;
                            final shiftStart =
                                (dienstplan['shift_start'] as Timestamp)
                                    .toDate();
                            final shiftEnd =
                                (dienstplan['shift_end'] as Timestamp).toDate();
                            final complete = dienstplan['complete'] as bool;
                            final dienstplanId = dienstplanDoc.id;

                            final isToday = shiftStart.year == now.year &&
                                shiftStart.month == now.month &&
                                shiftStart.day == now.day;

                            int workedShiftDuration = 0;
                            if (complete) {
                              final actualStart =
                                  (dienstplan['actual_start'] as Timestamp?)
                                          ?.toDate() ??
                                      shiftStart;
                              final actualEnd =
                                  (dienstplan['actual_end'] as Timestamp?)
                                          ?.toDate() ??
                                      shiftEnd;
                              workedShiftDuration = actualEnd
                                      .difference(actualStart)
                                      .inMinutes -
                                  (dienstplan['total_break_time'] as int? ?? 0);
                            }

                            final shiftDuration =
                                shiftEnd.difference(shiftStart).inMinutes;

                            return ListTile(
                              title: Text(
                                'Datum: ${DateFormat.yMMMMd().format(shiftStart)}',
                                style: TextStyle(
                                  color: complete ? Colors.green : Colors.black,
                                  fontWeight: complete
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                  'Schicht: ${DateFormat.Hm().format(shiftStart)} - ${DateFormat.Hm().format(shiftEnd)}'),
                              trailing: complete
                                  ? Text(
                                      'Gearbeitet: ${formatMinutes(workedShiftDuration)}',
                                      style:
                                          const TextStyle(color: Colors.green),
                                    )
                                  : isToday
                                      ? ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ClockInScreen(
                                                  shiftStart: shiftStart,
                                                  shiftEnd: shiftEnd,
                                                  shiftPlanId: dienstplanId,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Zur Schicht'),
                                        )
                                      : Text(
                                          'Geplant: ${formatMinutes(shiftDuration)}',
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                              onTap: complete
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditingScreen(
                                              shiftPlanId: dienstplanId),
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                                'Geplante Stunden: ${formatMinutes(plannedMinutes)}'),
                            Text(
                                'Gearbeitete Stunden: ${formatMinutes(workedMinutes)}'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshShiftPlans() async {
    setState(() {});
  }
}
