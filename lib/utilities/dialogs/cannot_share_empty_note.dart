import 'package:flutter/material.dart';
import 'package:tuto/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return showGenericDialog(
      context: context,
      title: "Sharing",
      content: "You cannot share empty note",
      optionBuilder: () => {"OK": null});
}
