import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/patients/domain/entities/patient_record.dart';
import 'date_utils.dart';

class PrescriptionPdfUtils {
  static Future<void> download({
    required PatientRecord patient,
    required PatientEncounter encounter,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Healthcare Mobile Unit Prescription',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${AppDateUtils.formatDate(encounter.visitDate)}'),
              pw.Text('Mobile Unit: ${encounter.unitName}'),
              pw.Text('Doctor/Nurse: ${encounter.officerName}'),
              pw.Text(
                  'Location: ${encounter.villageName}, ${encounter.district}, ${encounter.state}'),
              pw.Divider(),
              pw.Text('Patient Details',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Name: ${patient.name}'),
              pw.Text('Phone: ${patient.phone}'),
              pw.Text('Age/Gender: ${patient.age} / ${patient.gender}'),
              pw.Text('Address: ${patient.address}'),
              pw.SizedBox(height: 12),
              pw.Text('Vitals',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('BP: ${_emptyDash(encounter.bloodPressure)}'),
              pw.Text(
                  'O2 Saturation: ${_emptyDash(encounter.oxygenSaturation)}'),
              pw.Text('Temperature: ${_emptyDash(encounter.temperature)}'),
              pw.Text('Pulse: ${_emptyDash(encounter.pulseRate)}'),
              pw.SizedBox(height: 12),
              pw.Text('Diagnosis Summary',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(encounter.diagnosisSummary),
              pw.SizedBox(height: 12),
              pw.Text('Prescribed Medicines',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(encounter.prescribedMedicines),
              pw.SizedBox(height: 12),
              pw.Text('Recommended Tests',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_emptyDash(encounter.recommendedTests)),
              pw.SizedBox(height: 12),
              pw.Text('Remarks',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_emptyDash(encounter.remarks)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'prescription_${patient.phone}_${encounter.id}.pdf',
    );
  }

  static String _emptyDash(String value) =>
      value.trim().isEmpty ? '-' : value.trim();
}
