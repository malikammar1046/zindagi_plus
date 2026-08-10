import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  static const _biomarkers = <Map<String, dynamic>>[
    {
      'name': 'HbA1c',
      'value': '6.8%',
      'range': 'Normal: < 5.7%',
      'status': 'Borderline',
      'statusColor': Colors.orange,
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'LDL Cholesterol',
      'value': '130 mg/dL',
      'range': 'Optimal: < 100 mg/dL',
      'status': 'High',
      'statusColor': Colors.red,
      'icon': Icons.monitor_heart_outlined,
    },
    {
      'name': 'HDL Cholesterol',
      'value': '55 mg/dL',
      'range': 'Healthy: > 40 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.favorite_outline_rounded,
    },
    {
      'name': 'Triglycerides',
      'value': '148 mg/dL',
      'range': 'Normal: < 150 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.science_outlined,
    },
    {
      'name': 'Fasting Glucose',
      'value': '108 mg/dL',
      'range': 'Normal: 70–99 mg/dL',
      'status': 'Borderline',
      'statusColor': Colors.orange,
      'icon': Icons.opacity_rounded,
    },
    {
      'name': 'Vitamin D',
      'value': '18 ng/mL',
      'range': 'Normal: 20–50 ng/mL',
      'status': 'Low',
      'statusColor': Colors.red,
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'name': 'Haemoglobin',
      'value': '14.2 g/dL',
      'range': 'Normal: 13.5–17.5 g/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.bloodtype_outlined,
    },
    {
      'name': 'Creatinine',
      'value': '0.9 mg/dL',
      'range': 'Normal: 0.7–1.2 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.filter_alt_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Report Analysis')),
        body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          _SummaryCard(),
          const SizedBox(height: 20),
          // Counts row
          _StatusCountsRow(biomarkers: _biomarkers),
          const SizedBox(height: 20),
          Text(
            'Biomarker Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      color: colorScheme.primary, // Make it emerald solid background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded,
                  color: colorScheme.onPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Report Analysed',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mock OCR',
                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Blood_Report_July_2025.jpg',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '8 values extracted  ·  Analysed just now',
            style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.75), fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/upload/explanation');
            },
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text(
              'Explain in Simple Language',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
            ),
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
        _CountChip(count: normal, label: 'Normal', color: const Color(0xFF00674F)), // Emerald
        const SizedBox(width: 10),
        _CountChip(count: borderline, label: 'Borderline', color: Colors.orange),
        const SizedBox(width: 10),
        _CountChip(count: abnormal, label: 'Abnormal', color: Colors.red),
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
    final statusColor = biomarker['statusColor'] as Color;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  biomarker['range'] as String,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                biomarker['value'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
