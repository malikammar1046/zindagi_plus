import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  static const _biomarkers = <Map<String, dynamic>>[
    {
      'name': 'HbA1c',
      'value': '6.8%',
      'range': 'Normal: < 5.7%',
      'status': 'Borderline',
      'statusColor': 0xFFF59E0B,
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'LDL Cholesterol',
      'value': '130 mg/dL',
      'range': 'Optimal: < 100 mg/dL',
      'status': 'High',
      'statusColor': 0xFFEF4444,
      'icon': Icons.monitor_heart_outlined,
    },
    {
      'name': 'HDL Cholesterol',
      'value': '55 mg/dL',
      'range': 'Healthy: > 40 mg/dL',
      'status': 'Normal',
      'statusColor': 0xFF10B981,
      'icon': Icons.favorite_outline_rounded,
    },
    {
      'name': 'Triglycerides',
      'value': '148 mg/dL',
      'range': 'Normal: < 150 mg/dL',
      'status': 'Normal',
      'statusColor': 0xFF10B981,
      'icon': Icons.science_outlined,
    },
    {
      'name': 'Fasting Glucose',
      'value': '108 mg/dL',
      'range': 'Normal: 70–99 mg/dL',
      'status': 'Borderline',
      'statusColor': 0xFFF59E0B,
      'icon': Icons.opacity_rounded,
    },
    {
      'name': 'Vitamin D',
      'value': '18 ng/mL',
      'range': 'Normal: 20–50 ng/mL',
      'status': 'Low',
      'statusColor': 0xFFEF4444,
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'name': 'Haemoglobin',
      'value': '14.2 g/dL',
      'range': 'Normal: 13.5–17.5 g/dL',
      'status': 'Normal',
      'statusColor': 0xFF10B981,
      'icon': Icons.bloodtype_outlined,
    },
    {
      'name': 'Creatinine',
      'value': '0.9 mg/dL',
      'range': 'Normal: 0.7–1.2 mg/dL',
      'status': 'Normal',
      'statusColor': 0xFF10B981,
      'icon': Icons.filter_alt_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(title: const Text('Lab Report Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(),
          const SizedBox(height: 20),
          // Counts row
          _StatusCountsRow(biomarkers: _biomarkers),
          const SizedBox(height: 20),
          const Text(
            'Biomarker Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ..._biomarkers.map((b) => _BiomarkerCard(biomarker: b)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6B4F), Color(0xFF2D9C73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E6B4F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Report Analysed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mock OCR',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Blood_Report_July_2025.jpg',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '8 values extracted  ·  Analysed just now',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusCountsRow extends StatelessWidget {
  const _StatusCountsRow({required this.biomarkers});
  final List<Map<String, dynamic>> biomarkers;

  @override
  Widget build(BuildContext context) {
    int normal = 0, borderline = 0, abnormal = 0;
    for (final b in biomarkers) {
      final s = b['status'] as String;
      if (s == 'Normal') {
        normal++;
      } else if (s == 'Borderline') {
        borderline++;
      } else {
        abnormal++;
      }
    }

    return Row(
      children: [
        _CountChip(count: normal, label: 'Normal', color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        _CountChip(count: borderline, label: 'Borderline', color: const Color(0xFFF59E0B)),
        const SizedBox(width: 10),
        _CountChip(count: abnormal, label: 'Abnormal', color: const Color(0xFFEF4444)),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 11, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BiomarkerCard extends StatelessWidget {
  const _BiomarkerCard({required this.biomarker});
  final Map<String, dynamic> biomarker;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(biomarker['statusColor'] as int);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              biomarker['icon'] as IconData,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biomarker['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  biomarker['range'] as String,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                biomarker['value'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  biomarker['status'] as String,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
