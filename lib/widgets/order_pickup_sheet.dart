import 'package:flutter/material.dart';

class PickupData {
  final String address;
  final String phone;
  final DateTime pickupAt;
  final String? notes;
  PickupData({
    required this.address,
    required this.phone,
    required this.pickupAt,
    this.notes,
  });
}

Future<PickupData?> showPickupSheet(BuildContext context) {
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final formKey = GlobalKey<FormState>();

  Future<void> pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Choisir la date de collecte',
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Choisir l’heure de collecte',
    );
    if (time == null) return;

    selectedDate = date;
    selectedTime = time;
  }

  return showModalBottomSheet<PickupData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets;
      return Padding(
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Infos de collecte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète',
                  hintText: 'Ex: Cocody Angré, villa 12',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Adresse requise' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: 07 00 00 00 00',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 8) ? 'Téléphone invalide' : null,
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(
                  (selectedDate == null || selectedTime == null)
                      ? 'Choisir date & heure'
                      : 'Collecte: ${selectedDate!.day}/${selectedDate!.month} '
                        'à ${selectedTime!.hour.toString().padLeft(2, '0')}h'
                        '${selectedTime!.minute.toString().padLeft(2, '0')}',
                ),
                onPressed: () async {
                  await pickDateTime();
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Ex: Interphone défectueux, sonner 2 fois',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedDate == null || selectedTime == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Choisis la date & l’heure')),
                      );
                      return;
                    }
                    final dt = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    Navigator.of(ctx).pop(
                      PickupData(
                        address: addressCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        pickupAt: dt,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123252),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Confirmer'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
