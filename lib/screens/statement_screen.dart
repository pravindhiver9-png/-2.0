import 'package:flutter/material.dart';

class StatementScreen extends StatelessWidget {
  const StatementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "स्टेटमेंट बनाएं",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3F30),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "रिपोर्ट का प्रकार चुनें",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3F30),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReportOption("मासिक बचत स्टेटमेंट", "सभी सदस्यों की मासिक बचत का विवरण"),
                  const Divider(),
                  _buildReportOption("ऋण और भुगतान विवरण", "वितरित ऋण और प्राप्त भुगतानों की सूची"),
                  const Divider(),
                  _buildReportOption("समूह वार्षिक वित्तीय रिपोर्ट", "कुल फंड, बचत और ऋण का लेखा-जोखा"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3F30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download),
                label: const Text(
                  "PDF या Excel स्टेटमेंट डाउनलोड करें",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3F30),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const Radio(value: true, groupValue: true, onChanged: null, activeColor: Color(0xFF1F3F30)),
        ],
      ),
    );
  }
}
