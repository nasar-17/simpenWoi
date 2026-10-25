import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import 'deposit_sheet.dart';
import 'goal_form_sheet.dart';

Future<void> showGoalForm(BuildContext context, {SavingsGoal? goal}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => GoalFormSheet(goal: goal),
  );
}

Future<void> showDepositSheet(BuildContext context, SavingsGoal goal) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => DepositSheet(goal: goal),
  );
}
