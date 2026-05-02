import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/feedback_controller.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedbackController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your feedback helps us improve!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us what you like or what we can do better.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            
            // Category Selection
            const Text(
              'Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 10,
              children: controller.categories.map((category) {
                final isSelected = controller.category.value == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.setCategory(category);
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            )),
            
            const SizedBox(height: 30),
            
            // Rating
            const Text(
              'How would you rate your experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < controller.rating.value ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => controller.setRating(index + 1),
                );
              }),
            )),
            
            const SizedBox(height: 30),
            
            // Message input
            const Text(
              'Your Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.messageController,
              maxLines: 5,
              autofillHints: const [],
              decoration: InputDecoration(
                hintText: 'Describe your feedback here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Get.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => controller.submitFeedback(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
