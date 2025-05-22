import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

const String apiBase = "http://192.168.100.53:5000";

class DoctorPatientProfilePage extends StatefulWidget {
  final int doctorId;
  final int patientId;
  const DoctorPatientProfilePage(
      {required this.doctorId, required this.patientId});
  @override
  State<DoctorPatientProfilePage> createState() =>
      _DoctorPatientProfilePageState();
}

class _DoctorPatientProfilePageState extends State<DoctorPatientProfilePage> {
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> meds = [];
  List<Map<String, dynamic>> glucoseLogs = [];
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> logs = [];

  bool loading = true;
  int? homeCardIndex;

  final newDoseCtrl = TextEditingController();
  String? medToEdit;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  void dispose() {
    newDoseCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    final pRes = await http
        .get(Uri.parse("$apiBase/patient_profile/${widget.patientId}"));
    final mRes =
        await http.get(Uri.parse("$apiBase/medications/${widget.patientId}"));
    final gRes =
        await http.get(Uri.parse("$apiBase/glucose/${widget.patientId}"));
    final mealRes =
        await http.get(Uri.parse("$apiBase/meals/${widget.patientId}"));
    final actRes =
        await http.get(Uri.parse("$apiBase/activities/${widget.patientId}"));
    final appRes = await http
        .get(Uri.parse("$apiBase/appointments/patient/${widget.patientId}"));
    setState(() {
      profile = pRes.statusCode == 200 ? jsonDecode(pRes.body) : null;
      meds = mRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(mRes.body))
          : [];
      glucoseLogs = gRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(gRes.body))
          : [];
      meals = mealRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(mealRes.body))
          : [];
      activities = actRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(actRes.body))
          : [];
      appointments = appRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(appRes.body))
          : [];
      logs = [
        ...glucoseLogs.take(2).map((g) => {
              "type": "Glucose",
              "log": g,
              "time": g['timestamp'],
            }),
        ...meals.take(2).map((m) => {
              "type": "Meal",
              "log": m,
              "time": m['timestamp'],
            }),
        ...activities.take(2).map((a) => {
              "type": "Activity",
              "log": a,
              "time": a['timestamp'],
            }),
      ];
      logs.sort((a, b) =>
          (b['time'] as String).compareTo(a['time'] as String));
      loading = false;
    });
  }

  void updateMedication(String medId) async {
    if (newDoseCtrl.text.isEmpty) return;
    await http.put(
      Uri.parse("$apiBase/medications/$medId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "doctor_id": widget.doctorId,
        "dosage": newDoseCtrl.text,
      }),
    );
    newDoseCtrl.clear();
    setState(() => medToEdit = null);
    fetchAll();
  }

  Widget buildHomeCard(
      int idx, IconData icon, String title, String desc, Color color) {
    return InkWell(
      onTap: () => setState(() => homeCardIndex = idx),
      borderRadius: BorderRadius.circular(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 3,
        color: color.withOpacity(0.0),
        child: Container(
          height: 150,
          width: 230,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0),
                child: Icon(icon, color: color, size: 34),
              ),
              SizedBox(height: 13),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color.withOpacity(0.94))),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(desc,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.deepPurple[50],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: Text("Patient"),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (homeCardIndex == null) {
      return Scaffold(
        backgroundColor: Colors.deepPurple[50],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: Text(profile?['name'] ?? "Patient"),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 36.0, horizontal: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.deepPurple[100],
                    child: Icon(Icons.person,
                        size: 54, color: Colors.deepPurple[700]),
                  ),
                  SizedBox(height: 16),
                  Text(profile?['name'] ?? "",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.deepPurple[900])),
                  SizedBox(height: 4),
                  Text(
                      "${profile?['email'] ?? ""}  ·  ${profile?['city'] ?? ""}",
                      style: TextStyle(
                          color: Colors.deepPurple[300],
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 26),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      buildHomeCard(
                          0,
                          Icons.info_outline,
                          "Profile",
                          "View patient's full profile details.",
                          Colors.deepPurple),
                      buildHomeCard(
                          1,
                          Icons.medical_services,
                          "Manage Medications",
                          "View, edit, or remove medications.",
                          Color(0xFFE91E63)),
                      buildHomeCard(
                          2,
                          Icons.list_alt,
                          "Recent Logs",
                          "See the last 6 logs (glucose, meals, activity).",
                          Color(0xFFFFCA28)),
                      buildHomeCard(
                          3,
                          Icons.show_chart,
                          "Charts",
                          "Visualize glucose, meals, and activity data.",
                          Color(0xFF26A69A)),
                      buildHomeCard(4, Icons.date_range, "Appointments",
                          "See upcoming appointments.", Color(0xFF5C6BC0)),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text([
          "Profile",
          "Medications",
          "Logs",
          "Charts",
          "Appointments"
        ][homeCardIndex!]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => homeCardIndex = null),
        ),
      ),
      body: [
        _buildProfileCard(),
        _buildMedicationsCard(),
        _buildLogsCard(),
        _buildChartsCard(),
        _buildAppointmentsCard(),
      ][homeCardIndex!],
    );
  }

  Widget _buildProfileCard() {
    if (profile == null) return Center(child: Text("No profile data"));
    return SingleChildScrollView(
      padding: EdgeInsets.all(22),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.deepPurple[100],
                  child: Icon(Icons.person,
                      size: 48, color: Colors.deepPurple[700]),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(profile?['name'] ?? "",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 23,
                        color: Colors.deepPurple[900])),
              ),
              SizedBox(height: 18),
              _profileRow("Email", profile?['email']),
              _profileRow("Phone", profile?['phone']),
              _profileRow("DOB", profile?['dob']),
              _profileRow("Gender", profile?['gender']),
              _profileRow("City", profile?['city']),
              _profileRow("Country", profile?['country']),
              _profileRow("Diabetes Type", profile?['diabetes_type']),
              _profileRow("Weight (kg)", profile?['weight']),
              _profileRow("Health Background", profile?['health_background']),
              _profileRow("Emergency Contact", profile?['emergency_contact']),
              _profileRow("Emergency Phone", profile?['emergency_phone']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 142,
                child: Text("$label:",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple[400]))),
            Expanded(
                child: Text(
              value == null || value.toString().isEmpty
                  ? "-"
                  : value.toString(),
              style: TextStyle(
                  color: Colors.deepPurple[900],
                  fontWeight: FontWeight.w500,
                  fontSize: 15),
            )),
          ],
        ),
      );

  Widget _buildMedicationsCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ...meds.isEmpty
              ? [
                  Center(
                      child: Text("No medications.",
                          style: TextStyle(
                              color: Color(0xFF607D8B), fontSize: 16)))
                ]
              : meds.map((m) => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        "${m['med_name']} (${m['med_type']})",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63)),
                      ),
                      subtitle: Text("Dosage: ${m['dosage']}",
                          style: TextStyle(fontSize: 15)),
                      trailing: medToEdit == m['id'].toString()
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 70,
                                  child: TextField(
                                    controller: newDoseCtrl,
                                    decoration: InputDecoration(
                                        hintText: "New dosage",
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8)),
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () =>
                                      updateMedication(m['id'].toString()),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Color(0xFFE91E63)),
                                  onPressed: () =>
                                      setState(() => medToEdit = null),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Colors.deepPurple),
                                  onPressed: () {
                                    newDoseCtrl.text = m['dosage'] ?? '';
                                    setState(
                                        () => medToEdit = m['id'].toString());
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Color(0xFFE91E63)),
                                  onPressed: () async {
                                    await http.delete(Uri.parse(
                                        "$apiBase/medications/${m['id']}"));
                                    fetchAll();
                                  },
                                ),
                              ],
                            ),
                    ),
                  ))
        ],
      ),
    );
  }

  Widget _buildLogsCard() {
    if (logs.isEmpty) return Center(child: Text("No recent logs."));
    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: logs.length.clamp(0, 6),
      itemBuilder: (context, idx) {
        final l = logs[idx];
        final type = l['type'];
        final data = l['log'];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              type == "Glucose"
                  ? Icons.bloodtype
                  : type == "Meal"
                      ? Icons.restaurant
                      : Icons.directions_run,
              color: type == "Glucose"
                  ? Color(0xFFE91E63)
                  : type == "Meal"
                      ? Color(0xFFFFCA28)
                      : Color(0xFF26A69A),
              size: 32,
            ),
            title: Text(
              type == "Glucose"
                  ? "Glucose: ${data['glucose_level']} (${data['context']})"
                  : type == "Meal"
                      ? "${data['description']} (${data['meal_type']})"
                      : "${data['activity_type']} (${data['duration_minutes']} min)",
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            subtitle: Text(
              type == "Glucose"
                  ? "${data['timestamp']} — ${data['category']}"
                  : type == "Meal"
                      ? "${data['timestamp']}, ${data['calories']} cal, ${data['carbs']}g carbs"
                      : "${data['timestamp']} | Calories: ${data['calories_burned'] ?? '-'}",
              style: TextStyle(fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Glucose Chart",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple[700])),
          _buildGlucoseChart(glucoseLogs),
          SizedBox(height: 22),
          Text("Meal Calories Chart",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple[700])),
          _buildMealChart(meals),
          SizedBox(height: 22),
          Text("Activity Calories Chart",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple[700])),
          _buildActivityChart(activities),
        ],
      ),
    );
  }

  Widget _buildAppointmentsCard() {
    if (appointments.isEmpty) {
      return Center(
        child: Text("No appointments scheduled.",
            style: TextStyle(color: Color(0xFF78909C), fontSize: 17)),
      );
    }
    return ListView(
      padding: EdgeInsets.all(24),
      children: appointments.map((a) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(Icons.event, color: Color(0xFF5C6BC0), size: 32),
            title: Text(
              "With Dr. ${a['doctor_name']} on ${a['appointment_time'].replaceAll('T', ' ').substring(0, 16)}",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("Status: ${a['status']}\n${a['notes'] ?? ''}",
                style: TextStyle(fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlucoseChart(List<Map<String, dynamic>> logs) {
  if (logs.length < 2) return Text("Not enough data");
  final chartLogs = logs.take(7).toList().reversed.toList();
  final maxValue = chartLogs
      .map((g) => (g['glucose_level'] as num).toDouble())
      .reduce((a, b) => a > b ? a : b);
  final minValue = chartLogs
      .map((g) => (g['glucose_level'] as num).toDouble())
      .reduce((a, b) => a < b ? a : b);
  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= chartLogs.length) return Container();
                final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                      style: TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: ((maxValue - minValue) / 4).clamp(1, double.infinity),
              getTitlesWidget: (v, meta) => Text(v.toInt().toString()),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chartLogs.length,
              (i) => FlSpot(i.toDouble(),
                  (chartLogs[i]['glucose_level'] as num).toDouble()),
            ),
            isCurved: true,
            gradient: LinearGradient(colors: [
              Colors.deepPurple[400] ?? Colors.deepPurple, // Fallback to Colors.deepPurple
              Colors.deepPurple[200] ?? Colors.deepPurpleAccent, // Fallback to Colors.deepPurpleAccent
            ]),
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                (Colors.deepPurple[400] ?? Colors.deepPurple).withOpacity(0.2),
                (Colors.deepPurple[200] ?? Colors.deepPurpleAccent).withOpacity(0.02),
              ]),
            ),
          ),
        ],
        minY: (minValue - 10).clamp(0, double.infinity),
        maxY: maxValue + 10,
      ),
    ),
  );
}

  Widget _buildMealChart(List<Map<String, dynamic>> logs) {
    if (logs.length < 2) return Text("Not enough data");
    final chartLogs = logs.take(7).toList().reversed.toList();
    final maxVal = chartLogs
        .map((m) => (m['calories'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
              show: true,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= chartLogs.length) return Container();
                  final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                        style: TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 38),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: 0,
          maxY: maxVal + 50,
          barGroups: List.generate(
            chartLogs.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (chartLogs[i]['calories'] as num?)?.toDouble() ?? 0,
                  color: Color(0xFFFFCA28),
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart(List<Map<String, dynamic>> logs) {
    if (logs.length < 2) return Text("Not enough data");
    final chartLogs = logs.take(7).toList().reversed.toList();
    final maxVal = chartLogs
        .map((a) => (a['calories_burned'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
              show: true,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 38),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= chartLogs.length) return Container();
                  final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                        style: TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: 0,
          maxY: maxVal + 50,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                chartLogs.length,
                (i) => FlSpot(i.toDouble(),
                    (chartLogs[i]['calories_burned'] as num?)?.toDouble() ?? 0),
              ),
              isCurved: true,
              color: Color(0xFF26A69A),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF26A69A).withOpacity(0.3),
                    Color(0xFF26A69A).withOpacity(0.05)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}