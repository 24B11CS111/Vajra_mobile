import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/vajra_colors.dart';
import '../../shared/widgets/vajra_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _nextPage() async {
    if (_currentPage < 4) {
      _pageController.nextPage(duration: 350.ms, curve: Curves.easeOutCirc);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vajra_onboarding_completed', true);
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                  _buildPage5(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => AnimatedContainer(
                        duration: 250.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? VajraColors.accent : VajraColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  VajraButton(
                    text: _currentPage == 4 ? 'Get Started' : 'Continue',
                    onPressed: _nextPage,
                  ).animate().fadeIn(duration: 350.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return _BasePage(
      title: 'Welcome to VAJRA',
      subtitle: 'Your Personal AI Companion.',
      content: const Icon(Icons.auto_awesome, size: 120, color: VajraColors.accent)
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2.seconds),
    );
  }

  Widget _buildPage2() {
    return _BasePage(
      title: 'Choose your goal.',
      subtitle: 'What are we working towards?',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SelectionItem(title: 'Graduate with distinction'),
          _SelectionItem(title: 'Crack placements'),
          _SelectionItem(title: 'Build a startup'),
          _SelectionItem(title: 'Master AI'),
          _SelectionItem(title: 'Stay organized'),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return _BasePage(
      title: 'What should VAJRA remember?',
      subtitle: 'Your brain, safely backed up.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SelectionItem(title: 'Assignments', isSelected: true),
          _SelectionItem(title: 'Projects', isSelected: true),
          _SelectionItem(title: 'Goals', isSelected: true),
          _SelectionItem(title: 'Birthdays', isSelected: true),
          _SelectionItem(title: 'Everything I choose', isSelected: true),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return _BasePage(
      title: 'Permissions.',
      subtitle: 'To be proactive, VAJRA needs access.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _PermissionItem(icon: Icons.calendar_today, title: 'Calendar', desc: 'To auto-schedule tasks.'),
          _PermissionItem(icon: Icons.notifications, title: 'Notifications', desc: 'To tap your shoulder.'),
          _PermissionItem(icon: Icons.mic, title: 'Microphone', desc: 'To listen when you speak.'),
          _PermissionItem(icon: Icons.storage, title: 'Storage', desc: 'To read your syllabuses.'),
        ],
      ),
    );
  }

  Widget _buildPage5() {
    return _BasePage(
      title: 'Ready.',
      subtitle: 'Your companion is online.',
      content: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: VajraColors.accent, width: 2),
        ),
        child: const Icon(Icons.check, size: 48, color: VajraColors.accent),
      ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
    );
  }
}

class _BasePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;

  const _BasePage({required this.title, required this.subtitle, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.displayMedium).animate().fadeIn().slideX(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: VajraColors.secondaryText)).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(child: content.animate().fadeIn(delay: 300.ms)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionItem extends StatefulWidget {
  final String title;
  final bool isSelected;
  const _SelectionItem({required this.title, this.isSelected = false});

  @override
  State<_SelectionItem> createState() => _SelectionItemState();
}

class _SelectionItemState extends State<_SelectionItem> {
  late bool selected;
  @override
  void initState() {
    super.initState();
    selected = widget.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => selected = !selected),
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? VajraColors.accent : Colors.transparent,
          border: Border.all(color: selected ? VajraColors.accent : VajraColors.elevatedSurface),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? VajraColors.primaryBackground : VajraColors.secondaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(widget.title, style: TextStyle(color: selected ? VajraColors.primaryBackground : VajraColors.primaryText, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _PermissionItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: VajraColors.elevatedSurface, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: VajraColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(desc, style: const TextStyle(color: VajraColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
