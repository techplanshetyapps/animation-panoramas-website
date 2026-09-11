import 'package:flutter/material.dart';

class TelemetryObservabilityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clickHouseLogs;
  final Map<String, dynamic> ecosystemData;

  const TelemetryObservabilityWidget({
    Key? key,
    required this.clickHouseLogs,
    required this.ecosystemData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Unified Observability & Telemetry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(ecosystemData['status'] ?? 'ONLINE'),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: TextStyle(color: Colors.green.shade800),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Grafana Cloud Status Section
            _buildInfoRow(
              Icons.cloud_done,
              'Grafana Cloud Endpoint',
              'https://micronacho2399.grafana.net (Active)',
              Colors.blue,
            ),
            const SizedBox(height: 12),

            // Parallel API Telemetry Status
            _buildInfoRow(
              Icons.bolt,
              'Parallel API Search',
              ecosystemData['parallel_api_status'] ?? 'ACTIVE',
              Colors.orange,
            ),
            const SizedBox(height: 16),

            // ClickHouse OLAP Execution Logs Header
            const Text(
              'ClickHouse OLAP Query Execution States',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // ClickHouse Logs List View
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: clickHouseLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No telemetry logs recorded yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: clickHouseLogs.length,
                      itemBuilder: (context, index) {
                        final log = clickHouseLogs[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                          title: Text(
                            'Hour: ${log['hr']} | Metric Avg: ${log['avg_metric']}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Tool: ${log['tool'] ?? 'get_grafana_metrics'}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}