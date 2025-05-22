import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'doctor_profile_dialog.dart';
import 'doctor_patients_tab.dart';
import 'doctor_appointments_tab.dart';
import 'doctor_faq_tab.dart';
import 'doctor_articles_tab.dart';
import 'doctor_challenges_tab.dart';
import 'doctor_chat_tab.dart';

const String apiBase = "http://192.168.100.53:5000";

class DoctorHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const DoctorHome({required this.user, Key? key}) : super(key: key);

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  Map<String, dynamic>? doctorProfile;
  bool loadingProfile = false;

  Map<String, dynamic>? selectedPatientForChat;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);
    fetchDoctorProfile();
    tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void fetchDoctorProfile() async {
    setState(() => loadingProfile = true);
    final res = await http
        .get(Uri.parse("$apiBase/doctor_profile/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => doctorProfile = Map<String, dynamic>.from(jsonDecode(res.body)));
    }
    setState(() => loadingProfile = false);
  }

  void showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => DoctorProfileDialog(
        doctorProfile: doctorProfile,
        loading: loadingProfile,
        onRefresh: fetchDoctorProfile,
      ),
    );
  }

  void onPatientChatSelected(Map<String, dynamic> patient) {
    setState(() {
      selectedPatientForChat = patient;
      tabController.index = 5;
    });
  }

  Widget _tabButton(IconData icon, String label, int index) {
    final bool isSelected = tabController.index == index;
    // unselected: light purple background, deepPurple text
    final bgColor = isSelected ? Colors.deepPurple : Colors.deepPurple.withOpacity(0.1);
    final textColor = isSelected ? Colors.white : Colors.deepPurple;
    final iconColor = isSelected ? Colors.white : Colors.deepPurple;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton.icon(
        onPressed: () => setState(() => tabController.index = index),
        icon: Icon(icon, color: iconColor),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.deepPurple, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Welcome, ${widget.user['name']} (${widget.user['role']})",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.deepPurple, size: 30),
            tooltip: 'Profile',
            onPressed: showProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 28),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabButton(Icons.people, "Patients", 0),
                _tabButton(Icons.schedule, "Appointments", 1),
                _tabButton(Icons.question_answer, "FAQ", 2),
                _tabButton(Icons.article, "Articles", 3),
                _tabButton(Icons.flag, "Challenges", 4),
                _tabButton(Icons.chat, "Chat", 5),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          DoctorPatientsTab(doctorId: widget.user['id'], onPatientChatSelected: onPatientChatSelected),
          DoctorAppointmentsTab(doctorId: widget.user['id']),
          DoctorFaqTab(doctor: widget.user),
          DoctorArticlesTab(user: widget.user),
          DoctorChallengesTab(doctor: widget.user),
          DoctorChatTab(doctor: widget.user, selectedPatient: selectedPatientForChat, onChatClosed: () => setState(() => selectedPatientForChat = null)),
        ],
      ),
    );
  }
}
