import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationPage extends StatefulWidget {
  final Event event;
  final TicketTier selectedTier;

  const RegistrationPage({
    super.key,
    required this.event,
    required this.selectedTier,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Detail Event',
        onBackPressed: () => Navigator.pop(context),
      ),
    );
  }
}