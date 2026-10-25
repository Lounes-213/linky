import 'package:flutter/material.dart';
import '../core/theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              Text('Trending Categories', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCategories(context),
              const SizedBox(height: 32),
              Text('Suggested for you', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(child: _buildSuggestedList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? LinkyColors.glassWhite 
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: onSurface.withValues(alpha: 0.38)),
          const SizedBox(width: 12),
          Text('Search creators, tags...', style: TextStyle(color: onSurface.withValues(alpha: 0.38))),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = ['Music', 'Tech', 'NFT', 'Gaming', 'Art', 'Sports'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) => _buildCategoryChip(context, cat)).toList(),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? LinkyColors.glassWhite 
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? LinkyColors.glassBorder 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Text(label, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSuggestedList(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final suggestedRaw = [
      {'name': 'Alex Rivera', 'handle': '@arivera.art', 'img': 'https://i.pravatar.cc/150?u=20', 'isSubscribed': true},
      {'name': 'Sofia Chen', 'handle': '@sofia.codes', 'img': 'https://i.pravatar.cc/150?u=21', 'isSubscribed': false},
      {'name': 'Jordan Lee', 'handle': '@jlee_photo', 'img': 'https://i.pravatar.cc/150?u=22', 'isSubscribed': true},
      {'name': 'Mila Kunis', 'handle': '@mila_fit', 'img': 'https://i.pravatar.cc/150?u=23', 'isSubscribed': false},
      {'name': 'TechZone', 'handle': '@techzone', 'img': 'https://i.pravatar.cc/150?u=24', 'isSubscribed': true},
    ];

    final suggested = List<Map<String, Object>>.from(suggestedRaw);
    suggested.sort((a, b) {
      final aSub = a['isSubscribed'] as bool;
      final bSub = b['isSubscribed'] as bool;
      if (aSub && !bSub) return -1;
      if (!aSub && bSub) return 1;
      return 0;
    });

    return ListView.builder(
      itemCount: suggested.length,
      itemBuilder: (context, index) {
        final person = suggested[index];
        final isSubscribed = person['isSubscribed'] as bool;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              CircleAvatar(radius: 25, backgroundImage: NetworkImage(person['img'] as String)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person['name'] as String, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(person['handle'] as String, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSubscribed ? Colors.transparent : LinkyColors.neonGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSubscribed ? onSurface.withValues(alpha: 0.2) : Colors.transparent),
                ),
                child: Text(
                  isSubscribed ? 'Subscribed' : 'Subscribe',
                  style: TextStyle(
                    color: isSubscribed ? onSurface : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
