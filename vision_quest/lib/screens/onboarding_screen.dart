import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _currentPage = 0;

  // Step 1 : nom
  final _nameCtrl = TextEditingController();

  // Step 2 : âge
  int _age = 8;

  // Step 3 : conditions
  final Set<String> _conditions = {};
  static const _conditionOptions = {
    '👁️ Amblyopie (œil paresseux)': 'amblyopie',
    '🔀 Strabisme': 'strabisme',
    '🔭 Insuffisance de convergence': 'convergence',
    '🔲 Astigmatisme': 'astigmatisme',
    '📏 Myopie': 'myopie',
    '❓ Autre / Je ne sais pas': 'autre',
  };

  // Step 4 : œil dominant
  Eye _dominantEye = Eye.both;

  void _nextPage() {
    if (_currentPage < 3) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _createProfile();
    }
  }

  Future<void> _createProfile() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Héros' : _nameCtrl.text.trim(),
      age: _age,
      dominantEye: _dominantEye,
      conditions: _conditions.isEmpty ? ['autre'] : _conditions.toList(),
    );
    await context.read<UserService>().createProfile(profile);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppTheme.accentCyan
                            : AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _PageName(controller: _nameCtrl),
                    _PageAge(age: _age, onChanged: (v) => setState(() => _age = v)),
                    _PageConditions(
                      conditions: _conditions,
                      options: _conditionOptions,
                      onToggle: (v) => setState(() {
                        if (_conditions.contains(v)) _conditions.remove(v);
                        else _conditions.add(v);
                      }),
                    ),
                    _PageEye(
                      selected: _dominantEye,
                      onChanged: (e) => setState(() => _dominantEye = e),
                    ),
                  ],
                ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: _currentPage < 3 ? 'Suivant →' : 'Commencer l\'aventure ! 🚀',
                  onTap: _nextPage,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Onboarding pages ──────────────────────────────────────────────

class _PageName extends StatelessWidget {
  final TextEditingController controller;
  const _PageName({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'Comment tu t\'appelles ?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ton nom apparaîtra dans l\'aventure !',
            style: TextStyle(color: AppTheme.textSecond),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Mon prénom',
              hintStyle: const TextStyle(color: AppTheme.textSecond),
              filled: true,
              fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentCyan, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.accentCyan.withOpacity(0.4), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentCyan, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageAge extends StatelessWidget {
  final int age;
  final ValueChanged<int> onChanged;
  const _PageAge({required this.age, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎂', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'Quel âge as-tu ?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            '$age ans',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppTheme.accentCyan),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accentCyan,
              inactiveTrackColor: AppTheme.bgSurface,
              thumbColor: AppTheme.accentCyan,
              overlayColor: AppTheme.accentCyan.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 6,
            ),
            child: Slider(
              value: age.toDouble(),
              min: 4, max: 60,
              divisions: 56,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('4 ans', style: TextStyle(color: AppTheme.textSecond)),
              Text('60 ans', style: TextStyle(color: AppTheme.textSecond)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageConditions extends StatelessWidget {
  final Set<String> conditions;
  final Map<String, String> options;
  final ValueChanged<String> onToggle;
  const _PageConditions({required this.conditions, required this.options, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🏥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Ton trouble visuel ?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Plusieurs choix possibles (ou demande à tes parents !)',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: options.entries.map((e) {
                final selected = conditions.contains(e.value);
                return GestureDetector(
                  onTap: () => onToggle(e.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accentCyan.withOpacity(0.15) : AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppTheme.accentCyan : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              color: selected ? AppTheme.accentCyan : AppTheme.textPrimary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: AppTheme.accentCyan, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageEye extends StatelessWidget {
  final Eye selected;
  final ValueChanged<Eye> onChanged;
  const _PageEye({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'Ton œil directeur ?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'C\'est l\'œil que tu utilises pour viser (si tu ne sais pas, mets les deux !)',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...{Eye.left: '👈 Œil gauche', Eye.right: '👉 Œil droit', Eye.both: '🎯 Les deux / Je ne sais pas'}
              .entries.map((e) => GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected == e.key ? AppTheme.accentPurple.withOpacity(0.2) : AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == e.key ? AppTheme.accentPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: selected == e.key ? AppTheme.accentPurple : AppTheme.textPrimary,
                            fontWeight: selected == e.key ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected == e.key)
                        const Icon(Icons.radio_button_checked, color: AppTheme.accentPurple),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
