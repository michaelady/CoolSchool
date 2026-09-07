/// No-op on VM / mobile. Web paints DE/FR/EN/RO in the real DOM.
void showWebLocaleBar({
  required String selected,
  required void Function(String locale) onSelect,
}) {}

void hideWebLocaleBar() {}
