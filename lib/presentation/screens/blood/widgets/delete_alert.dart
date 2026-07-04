import 'package:flutter/material.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

void deleteAlert(BuildContext context, {required VoidCallback onConfirm}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Responsive clamped values
  final double dialogRadius = _clamp(screenWidth * 0.05, 12, 32);
  final double dialogPadding = _clamp(screenWidth * 0.04, 12, 32);
  final double titleFontSize = _clamp(screenWidth * 0.05, 18, 32);
  final double closeIconSize = _clamp(screenWidth * 0.06, 20, 40);
  final double messageFontSize = _clamp(screenWidth * 0.0375, 14, 24);
  final double buttonFontSize = _clamp(screenWidth * 0.03, 12, 20);
  final double buttonHeight = _clamp(screenHeight * 0.0625, 40, 64);
  final double buttonWidth = _clamp(screenWidth * 0.25, 80, 160);
  final double buttonRadius = _clamp(screenWidth * 0.025, 8, 16);
  final double borderWidth = _clamp(screenWidth * 0.00125, 0.5, 2);
  final double spacingSmall = _clamp(screenHeight * 0.0125, 8, 20);
  final double spacingLarge = _clamp(screenHeight * 0.025, 16, 40);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: closeIconSize),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: spacingSmall),

            Center(
              child: Text(
                'Are you sure you want to delete this blood details?',
                style: TextStyle(fontSize: messageFontSize),
              ),
            ),
            SizedBox(height: spacingLarge),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    height: buttonHeight,
                    width: buttonWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonRadius),
                      border: Border.all(
                        color: Colors.black,
                        width: borderWidth,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'YES',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: buttonHeight,
                    width: buttonWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonRadius),
                      border: Border.all(
                        color: Colors.black,
                        width: borderWidth,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'NO',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
