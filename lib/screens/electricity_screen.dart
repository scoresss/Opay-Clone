import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedDisco = 'Ikeja Electric';

  final List<String> discos = [
    'Ikeja Electric',
    'Eko Electric',
    'Abuja Disco',
    'PHED',
    'Enugu Disco',
  ];

  void _payElectricity() {
    if (_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg:
            '₦${_amountController.text} paid to $_selectedDisco (Meter: ${_meterController.text})',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      _meterController.clear();
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Electricity')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField(
                value: _selectedDisco,
                items: discos
                    .map((disco) => DropdownMenuItem(
                          value: disco,
                          child: Text(disco),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDisco = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Disco',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meter Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.length < 6 ? 'Enter valid meter number' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _payElectricity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Pay Now', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
