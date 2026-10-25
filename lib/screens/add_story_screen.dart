import 'package:flutter/material.dart';
import '../core/theme.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  String _selectedFilter = 'Normal';
  final List<String> _filters = ['Normal', 'Warm', 'Cool', 'B&W', 'Neon'];
  String _storyText = '';
  bool _showTextInput = false;
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getFilterColors(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _storyText.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _storyText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 64),
                            SizedBox(height: 14),
                            Text(
                              'Appuie pour capturer',
                              style: TextStyle(color: Colors.white38, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((f) {
                            final isSelected = _selectedFilter == f;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? LinkyColors.neonGreen
                                      : Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: LinkyColors.neonGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Publier',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.28,
              child: Column(
                children: [
                  _buildTool(Icons.text_fields, 'Texte', () {
                    setState(() => _showTextInput = true);
                  }),
                  const SizedBox(height: 20),
                  _buildTool(Icons.emoji_emotions_outlined, 'Emoji', () {}),
                  const SizedBox(height: 20),
                  _buildTool(Icons.draw_outlined, 'Dessin', () {}),
                  const SizedBox(height: 20),
                  _buildTool(Icons.music_note_outlined, 'Musique', () {}),
                  const SizedBox(height: 20),
                  _buildTool(Icons.link, 'Lien', () {}),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 4),
                          const Text('Galerie', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),

                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 4),
                          const Text('Retourner', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_showTextInput)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Écris quelque chose...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _storyText = _textController.text;
                            _showTextInput = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LinkyColors.neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Color> _getFilterColors() {
    switch (_selectedFilter) {
      case 'Warm':
        return [const Color(0xFF3A1200), const Color(0xFF7A3200)];
      case 'Cool':
        return [const Color(0xFF001830), const Color(0xFF003070)];
      case 'B&W':
        return [const Color(0xFF111111), const Color(0xFF333333)];
      case 'Neon':
        return [const Color(0xFF001500), Color.fromARGB(77, 57, 255, 20)];
      default:
        return [const Color(0xFF0D0D0D), const Color(0xFF1A1A2E)];
    }
  }

  Widget _buildTool(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
