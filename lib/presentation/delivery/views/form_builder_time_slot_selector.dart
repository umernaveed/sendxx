import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:sendx/data/models/manage_pick_up_request_meta/time_slot.dart';
import 'package:sizer/sizer.dart';

class FormBuilderTimeSlotSelector extends FormBuilderField<TimeSlot> {
  final List<TimeSlot> timeSlots;
  final String title;
  final Set<String>? disabledTimeSlots;

  FormBuilderTimeSlotSelector({
    Key? key,
    required String name,
    required this.timeSlots,
    required this.title,
    this.disabledTimeSlots,
    FormFieldValidator<TimeSlot>? validator,
    TimeSlot? initialValue,
    ValueChanged<TimeSlot?>? onChanged,
  }) : super(
          key: key,
          name: name,
          initialValue: initialValue,
          validator: validator,
          builder: (FormFieldState<TimeSlot?> field) {
            return _TimeSlotSelector(
              field: field,
              timeSlots: timeSlots,
              title: title,
              disabledTimeSlots: disabledTimeSlots,
            );
          },
        );
}

class _TimeSlotSelector extends StatelessWidget {
  final FormFieldState<TimeSlot?> field;
  final List<TimeSlot> timeSlots;
  final String title;
  final Set<String>? disabledTimeSlots;

  const _TimeSlotSelector({
    required this.field,
    required this.timeSlots,
    required this.title,
    this.disabledTimeSlots,
  });

  bool isDisabled(TimeSlot timeSlot) {
    if (disabledTimeSlots == null) return false;

    // Check if any ID in disabledTimeSlots matches the id of the given timeSlot
    return disabledTimeSlots
            ?.any((id) => id.toString() == timeSlot.id.toString()) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: title,
        errorText: field.errorText,
        labelStyle: context.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF7C7C7C),
          fontSize: 13.3.sp,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        border: InputBorder.none,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 1,
        children: timeSlots.map((timeSlot) {
          final isSelected = timeSlot == field.value;
          final disabled = isDisabled(timeSlot);

          return ChoiceChip(
            label: Text(
              '${timeSlot.startTime} - ${timeSlot.endTime}',
              style: TextStyle(
                color: disabled
                    ? Colors.grey
                    : isSelected
                        ? Colors.white
                        : Colors.black,
                fontSize: 10.sp,
              ),
            ),
            selected: isSelected,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12.4),
            backgroundColor: disabled
                ? Colors.grey.shade300
                : Colors.grey.withValues(alpha: 0.2),
            selectedColor: Theme.of(context).primaryColor,
            onSelected: disabled
                ? null // Disable interaction for disabled chips.
                : (selected) {
                    field.didChange(selected ? timeSlot : null);
                  },
          );
        }).toList(),
      ),
    );
  }
}
