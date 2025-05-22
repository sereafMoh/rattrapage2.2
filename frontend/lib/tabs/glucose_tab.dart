import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../patient_home.dart';

class GlucoseTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const GlucoseTab({required this.user});

  @override
  State<GlucoseTab> createState() => _GlucoseTabState();
}

class _GlucoseTabState extends State<GlucoseTab> {
  final glucoseCtrl = TextEditingController();
  String glucoseContext = "Fasting";
  List<Map<String, dynamic>> glucoseLogs = [];
  bool loadingGlucose = false;

  @override
  void initState() {
    super.initState();
    fetchGlucose();
  }

  @override
  void dispose() {
    glucoseCtrl.dispose();
    super.dispose();
  }

  void fetchGlucose() async {
    setState(() => loadingGlucose = true);
    final res = await http.get(Uri.parse("$apiBase/glucose/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => glucoseLogs = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingGlucose = false);
  }

  void addGlucose() async {
    final val = double.tryParse(glucoseCtrl.text);
    if (val == null) return;
    final res = await http.post(
      Uri.parse("$apiBase/glucose"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": widget.user['id'],
        "glucose_level": val,
        "context": glucoseContext,
      }),
    );
    glucoseCtrl.clear();
    fetchGlucose();
    if (res.statusCode == 200) {
      final resp = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Log recorded: ${resp["category"]}")),
      );
      final String category = resp["category"].toString().toLowerCase();
      if (category.contains("hyper") || category.contains("hypo")) {
        await http.post(
          Uri.parse("$apiBase/messages"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "sender_id": widget.user['id'],
            "receiver_id": resp["doctor_id"],
            "message":
                "ALERT: Patient logged $category (${val} mg/dL, $glucoseContext). Immediate attention may be needed."
          }),
        );
      }
    }
  }

  void deleteGlucose(int id) async {
    await http.delete(Uri.parse("$apiBase/glucose/$id"));
    fetchGlucose();
  }

  @override
  Widget build(BuildContext context) {
    final chartLogs = glucoseLogs.take(7).toList().reversed.toList();
    final maxValue = chartLogs.isNotEmpty
        ? chartLogs.map((g) => (g['glucose_level'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final minValue = chartLogs.isNotEmpty
        ? chartLogs.map((g) => (g['glucose_level'] as num).toDouble()).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          // Input row
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: glucoseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Glucose Level",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  DropdownButton<String>(
                    value: glucoseContext,
                    onChanged: (v) => setState(() => glucoseContext = v!),
                    items: [
                      DropdownMenuItem(value: "Fasting", child: Text("Fasting")),
                      DropdownMenuItem(value: "Post-meal", child: Text("Post-meal")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: addGlucose,
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 22),

          // Glucose Chart (moved above logs)
          if (chartLogs.length > 1)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: ((maxValue - minValue) / 3).clamp(1, double.infinity),
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                v.toInt().toString(),
                                style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= chartLogs.length) return Container();
                              final t = chartLogs[idx]['timestamp'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  t.substring(5, 10),
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              );
                            },
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
                            (i) => FlSpot(
                              i.toDouble(),
                              (chartLogs[i]['glucose_level'] as num).toDouble(),
                            ),
                          ),
                          isCurved: true,
                          gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.red,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(colors: [Colors.red.withOpacity(0.2), Colors.orange.withOpacity(0.02)]),
                          ),
                        ),
                      ],
                      minY: (minValue - 10).clamp(0, double.infinity),
                      maxY: maxValue + 10,
                    ),
                  ),
                ),
              ),
            ),

          SizedBox(height: 22),

          // Logs Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Glucose Logs:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 18),
            ),
          ),

          SizedBox(height: 8),

          // Glucose Logs List
          if (loadingGlucose)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                itemCount: glucoseLogs.length,
                separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.4),
                itemBuilder: (context, i) {
                  final g = glucoseLogs[i];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    child: ListTile(
                      leading: Icon(Icons.bloodtype, color: Colors.red[400]),
                      title: Text(
                        "Level: ${g['glucose_level']} (${g['context']})",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text("${g['timestamp']} — ${g['category']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[300]),
                        tooltip: "Delete Log",
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text("Delete Glucose Log"),
                              content: Text("Are you sure you want to delete this glucose log?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text("Delete"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) deleteGlucose(g['id']);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
