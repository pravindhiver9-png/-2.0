import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> transactions = const [
    {"title": "प्रवीण को ऋण दिया गया", "amount": "₹10,000", "date": "07/07/2025", "type": "loan"},
    {"title": "सीमा का भुगतान प्राप्त हुआ", "amount": "₹5,000", "date": "05/07/2025", "type": "payment"},
    {"title": "रमेश को ऋण दिया गया", "amount": "₹5,000", "date": "01/07/2025", "type": "loan"},
    {"title": "सुनीता की मासिक बचत", "amount": "₹1,000", "date": "28/06/2025", "type": "savings"},
    {"title": "राजेश का भुगतान प्राप्त हुआ", "amount": "₹3,000", "date": "25/06/2025", "type": "payment"},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "लेन-देन इतिहास",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3F30),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3F30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("नया लेन-देन"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  bool isLoan = tx["type"] == "loan";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F0EC),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLoan ? Icons.handshake : Icons.arrow_downward,
                                color: const Color(0xFF1F3F30),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx["title"]!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F3F30),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx["date"]!,
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          tx["amount"]!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isLoan ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
