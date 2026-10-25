import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  int _currentImageIndex = 0;
  bool _isLiked = false;
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.88,
    );
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isLiked = false;
      _currentImageIndex = 0; // Reset image index when swiping to new user
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentStory = widget.stories[_currentIndex];
    final storyTime = currentStory['time'] as String? ?? '';
    final images = currentStory['images'] as List;
    final currentImage = images[_currentImageIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Blurred background ──
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Image.network(
                currentImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => Container(color: const Color(0xFF1A1A1A)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          // ── PageView of story cards ──
          GestureDetector(
            onTapDown: (details) {
              if (details.localPosition.dy < size.height * 0.83) {
                if (details.localPosition.dx < size.width / 2) {
                  // Tap Left
                  if (_currentImageIndex > 0) {
                    setState(() => _currentImageIndex--);
                  } else {
                    _previousStory();
                  }
                } else {
                  // Tap Right
                  if (_currentImageIndex < images.length - 1) {
                    setState(() => _currentImageIndex++);
                  } else {
                    _nextStory();
                  }
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                final storyImages = story['images'] as List;
                final isCurrentPage = index == _currentIndex;
                final imgUrl = isCurrentPage ? storyImages[_currentImageIndex] : storyImages[0];

                return AnimatedScale(
                  scale: isCurrentPage ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 72,
                      bottom: 90,
                      left: isCurrentPage ? 0 : 8,
                      right: isCurrentPage ? 0 : 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: const Color(0xFF1A1A1A),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: LinkyColors.neonGreen,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, _) => Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Icon(Icons.person, size: 80, color: Colors.white24),
                            ),
                          ),
                          // Top gradient on card
                          Positioned(
                            top: 0, left: 0, right: 0,
                            height: 80,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Story segments indicator
                          if (isCurrentPage && storyImages.length > 1)
                            Positioned(
                              top: 55,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: List.generate(storyImages.length, (segIndex) {
                                  final isActive = segIndex <= _currentImageIndex;
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Avatars row (non-scrollable, synced with PageView) ──
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.stories.length, (index) {
                final story = widget.stories[index];
                final isActive = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? LinkyColors.neonGreen : Colors.white38,
                              width: isActive ? 2.5 : 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: isActive ? 18 : 14,
                            backgroundImage: NetworkImage((story['images'] as List)[0]),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          story['name'] as String,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white60,
                            fontSize: isActive ? 9 : 8,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Story time (when it was shared) ──
          if (storyTime.isNotEmpty)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white60, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'il y a $storyTime',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Close button ──
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── Bottom bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Envoyer un message...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isLiked = !_isLiked),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isLiked),
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
