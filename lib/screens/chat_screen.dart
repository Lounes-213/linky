import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, String> contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojis = false;
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! Ça va ? 😊', 'isMe': false, 'time': '10:32', 'liked': false},
    {'text': 'Ouais très bien, toi ? 🔥', 'isMe': true, 'time': '10:33', 'liked': false},
    {'text': 'Loved your latest portfolio drop !', 'isMe': false, 'time': '10:35', 'liked': true},
    {'text': 'Merci beaucoup ! 💚', 'isMe': true, 'time': '10:36', 'liked': false},
    {'text': 'On collabore sur le nouveau projet ?', 'isMe': false, 'time': '10:38', 'liked': false},
    {'text': 'Avec plaisir ! Je te prépare une démo', 'isMe': true, 'time': '10:40', 'liked': false},
  ];

  final List<String> _quickEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
  final List<String> _emojiList = [
    '😀','😂','🥹','😍','🤩','😎','🥳','😊','🫶','❤️',
    '🔥','✨','💯','🎉','🎊','🚀','💚','⚡','🌟','💎',
    '👍','👏','🙌','✌️','🤝','💪','🫡','🤘','🫰','👌',
    '😅','🤣','😭','😤','🫠','🥴','😴','🤯','🥶','🫣',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': text.trim(),
        'isMe': true,
        'time': TimeOfDay.now().format(context),
        'liked': false,
      });
      _isTyping = false;
    });
    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleLike(int index) {
    setState(() {
      _messages[index]['liked'] = !(_messages[index]['liked'] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(index),
            ),
          ),
          if (_showEmojis) _buildEmojiPanel(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.contact['img']!)),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: LinkyColors.neonGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contact['name']!, 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                overflow: TextOverflow.ellipsis,
              ),
              Text('En ligne', style: TextStyle(fontSize: 11, color: LinkyColors.neonGreen.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.more_vert, color: onSurface), onPressed: () {}),
      ],
    );
  }

  Widget _buildMessageBubble(int index) {
    final msg = _messages[index];
    final isMe = msg['isMe'] as bool;
    final isLiked = msg['liked'] as bool;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onDoubleTap: () => _toggleLike(index),
      onLongPress: () => _showMessageOptions(context, index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(radius: 14, backgroundImage: NetworkImage(widget.contact['img']!)),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? LinkyColors.neonGreen.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.1)
                        : onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isMe
                          ? LinkyColors.neonGreen.withValues(alpha: 0.2)
                          : onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(msg['text'] as String, style: TextStyle(color: onSurface, fontSize: 14, height: 1.4)),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg['time'] as String, style: TextStyle(color: onSurface.withValues(alpha: 0.35), fontSize: 10)),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all, size: 12, color: LinkyColors.neonGreen.withValues(alpha: 0.6)),
                    ],
                    if (isLiked) const Padding(padding: EdgeInsets.only(left: 4), child: Text('❤️', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, int index) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _quickEmojis.map((e) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _messages[index]['liked'] = true);
                },
                child: Text(e, style: const TextStyle(fontSize: 28)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Divider(color: onSurface.withValues(alpha: 0.1)),
            ListTile(
              leading: Icon(Icons.reply, color: onSurface.withValues(alpha: 0.7)),
              title: Text('Répondre', style: TextStyle(color: onSurface)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: onSurface.withValues(alpha: 0.7)),
              title: Text('Copier', style: TextStyle(color: onSurface)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: LinkyColors.neonCrimson),
              title: const Text('Supprimer', style: TextStyle(color: LinkyColors.neonCrimson)),
              onTap: () {
                setState(() => _messages.removeAt(index));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPanel() {
    return Container(
      height: 220,
      color: Theme.of(context).cardColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, childAspectRatio: 1),
        itemCount: _emojiList.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            _msgController.text += _emojiList[i];
            _msgController.selection = TextSelection.fromPosition(TextPosition(offset: _msgController.text.length));
          },
          child: Center(child: Text(_emojiList[i], style: const TextStyle(fontSize: 22))),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          if (!_isTyping) ...[
            GestureDetector(
              onTap: () {},
              child: Icon(Icons.image_outlined, color: onSurface.withValues(alpha: 0.5), size: 26),
            ),
            const SizedBox(width: 10),
          ],
          GestureDetector(
            onTap: () => setState(() => _showEmojis = !_showEmojis),
            child: Icon(
              _showEmojis ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: _showEmojis ? LinkyColors.neonGreen : onSurface.withValues(alpha: 0.5),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: onSurface.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: onSurface, fontSize: 14),
                maxLines: null,
                onChanged: (val) => setState(() => _isTyping = val.isNotEmpty),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.35)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isTyping
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: () => _sendMessage(_msgController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: LinkyColors.neonGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
