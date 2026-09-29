import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const _items = <({String q, String a})>[
    (
      q: 'How do I invite roommates?',
      a: 'Open More → Invite flatmates, or copy the FLAT-XXXX code from Household settings. '
          'Your roommate signs up, then joins with that code. Codes are not case-sensitive.',
    ),
    (
      q: 'What do Equal, Custom, and % Split mean?',
      a: 'Equal divides the amount among selected people, with leftover paisa given out one at a time so the total still matches. '
          'Custom lets you type a rupee amount per person. % Split uses percentages that must add up to 100%.',
    ),
    (
      q: 'Who can change budgets and the flat name?',
      a: 'Only the person who created the flat (the owner) can set category limits, member quotas, custom categories, and the flat name. '
          'Everyone else can view budgets and add expenses.',
    ),
    (
      q: 'How does Settle up work?',
      a: 'CoSpend nets who paid vs who owed, then suggests the fewest transfers. '
          'Tap Record after the money has actually been sent so balances update. History stays on the Settle up screen.',
    ),
    (
      q: 'Can I leave or switch flats?',
      a: 'Yes. More → Leave flat removes you from the current household. '
          'Join another flat with a new invite code; your old membership is cleaned up. Past expenses stay in that flat’s history.',
    ),
    (
      q: 'Why are amounts in paisa / Rs.?',
      a: 'Everything is stored as whole paisa (100 paisa = Rs. 1) so splits never pick up floating-point errors. '
          'You still type rupees as usual when adding an expense.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return CoSpendCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  item.q,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
                children: [
                  Text(
                    item.a,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
