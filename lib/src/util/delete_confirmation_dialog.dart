import 'package:flutter/material.dart';

class DeleteConfirmationDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String reasonLabel,
    required Future<void> Function(String reason) onDelete,
    String? Function()? getErrorMessage,
    String deleteButtonText = 'Delete',
    String cancelButtonText = 'Cancel',
  }) async {
    final TextEditingController reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return _DeleteConfirmationDialogContent(
          title: title,
          message: message,
          reasonLabel: reasonLabel,
          reasonController: reasonController,
          onDelete: onDelete,
          getErrorMessage: getErrorMessage,
          deleteButtonText: deleteButtonText,
          cancelButtonText: cancelButtonText,
        );
      },
    );

    reasonController.dispose();
  }
}

class _DeleteConfirmationDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final String reasonLabel;
  final TextEditingController reasonController;
  final Future<void> Function(String reason) onDelete;
  final String? Function()? getErrorMessage;
  final String deleteButtonText;
  final String cancelButtonText;

  const _DeleteConfirmationDialogContent({
    required this.title,
    required this.message,
    required this.reasonLabel,
    required this.reasonController,
    required this.onDelete,
    this.getErrorMessage,
    required this.deleteButtonText,
    required this.cancelButtonText,
  });

  @override
  State<_DeleteConfirmationDialogContent> createState() =>
      _DeleteConfirmationDialogContentState();
}

class _DeleteConfirmationDialogContentState
    extends State<_DeleteConfirmationDialogContent> {
  String? errorMessage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: widget.reasonController,
            decoration: InputDecoration(
              labelText: widget.reasonLabel,
              border: const OutlineInputBorder(),
              errorText: errorMessage,
            ),
            maxLines: 3,
            enabled: !isLoading,
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Deleting...'),
              ],
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(widget.cancelButtonText),
        ),
        TextButton(
          onPressed: isLoading ? null : _handleDelete,
          child: Text(
            widget.deleteButtonText,
            style: TextStyle(color: isLoading ? Colors.grey : Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    // Validate input
    if (widget.reasonController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please provide a reason for deletion';
      });
      return;
    }

    // Clear previous error and show loading
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      // Call the delete function and wait for completion
      await widget.onDelete(widget.reasonController.text.trim());

      // Check if there was an error during deletion (if getErrorMessage is provided)
      if (widget.getErrorMessage != null) {
        final error = widget.getErrorMessage!();
        if (error != null) {
          setState(() {
            errorMessage = error;
            isLoading = false;
          });
          return;
        }
      }

      // Success - close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to delete: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }
}
