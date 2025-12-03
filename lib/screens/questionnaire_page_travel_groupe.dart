import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class TravelGroupPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const TravelGroupPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<TravelGroupPage> createState() => _TravelGroupPageState();
}

class _TravelGroupPageState extends State<TravelGroupPage> {
  String? _selectedGroup;

  final List<TravelGroupOption> _groupOptions = [
    TravelGroupOption(
      id: 'solo',
      label: 'En solo',
      icon: Icons.person,
      color: Colors.blue,
      description: 'Voyage en solitaire',
      peopleCount: 1,
    ),
    TravelGroupOption(
      id: 'couple',
      label: 'En couple',
      icon: Icons.favorite,
      color: Colors.pink,
      description: 'À deux, romantique',
      peopleCount: 2,
    ),
    TravelGroupOption(
      id: 'friends',
      label: 'Entre ami(e)s',
      icon: Icons.groups,
      color: Colors.orange,
      description: 'Avec des amis',
      peopleCount: 4,
    ),
    TravelGroupOption(
      id: 'family',
      label: 'En famille',
      icon: Icons.family_restroom,
      color: Colors.green,
      description: 'Voyage familial',
      peopleCount: 4,
    ),
  ];

  void _selectGroup(String groupId) {
    setState(() {
      _selectedGroup = groupId;
    });
  }

  void _nextQuestion() {
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de voyage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedOption = _groupOptions.firstWhere((opt) => opt.id == _selectedGroup);
    
    widget.preferences.travelGroup = _selectedGroup;
    widget.preferences.travelGroupSize = selectedOption.peopleCount;
    
    print('Type de voyage: $_selectedGroup (${selectedOption.peopleCount} personne(s))');
    
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(),
              const SizedBox(height: 50),
              _buildGroupOptions(),
              const SizedBox(height: 50),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
      'Avec qui voyagez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGroupOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGroupCard(_groupOptions[0]), // Solo
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGroupCard(_groupOptions[1]), // Couple
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGroupCard(_groupOptions[2]), // Amis
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGroupCard(_groupOptions[3]), // Famille
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupCard(TravelGroupOption option) {
    final isSelected = _selectedGroup == option.id;
    
    return GestureDetector(
      onTap: () => _selectGroup(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [option.color, option.color]
                : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? option.color : Colors.white.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isSelected ? 16 : 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                size: isSelected ? 50 : 40,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              option.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSelected ? 18 : 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              option.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${option.peopleCount} ${option.peopleCount > 1 ? "personnes" : "personne"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final hasSelection = _selectedGroup != null;
    
    return Column(
      children: [
        if (hasSelection) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _groupOptions.firstWhere((opt) => opt.id == _selectedGroup).icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Vous voyagez ${_groupOptions.firstWhere((opt) => opt.id == _selectedGroup).label.toLowerCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        ElevatedButton(
          onPressed: hasSelection ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1a3a52),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
            disabledBackgroundColor: Colors.white.withOpacity(0.5),
          ),
          child: const Text(
            'Suivant',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// Classe pour représenter une option de groupe
class TravelGroupOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final int peopleCount;

  TravelGroupOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.peopleCount,
  });
}