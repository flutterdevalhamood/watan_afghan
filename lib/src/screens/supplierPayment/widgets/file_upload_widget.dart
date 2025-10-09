import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable file upload widget
class FileUploadSection extends StatelessWidget {
  final List<XFile> selectedFiles;
  final VoidCallback onPickFiles;
  final Function(int) onRemoveFile;

  const FileUploadSection({
    super.key,
    required this.selectedFiles,
    required this.onPickFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach Files',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPickFiles,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Choose Files',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedFiles.isEmpty
                        ? 'No file chosen'
                        : '${selectedFiles.length} file(s) selected',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedFiles.asMap().entries.map((entry) {
                  int index = entry.key;
                  XFile file = entry.value;
                  return Chip(
                    label: Text(
                      file.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onRemoveFile(index),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}
