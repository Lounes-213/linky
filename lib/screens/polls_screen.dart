import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api/api_service.dart';
import '../core/widgets/neu_button.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _activePolls = [];
  List<Map<String, dynamic>> _closedPolls = [];
  List<Map<String, dynamic>> _myVotesPolls = [];
  bool _isLoadingActive = true;
  bool _isLoadingClosed = true;
  bool _isLoadingMyVotes = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPolls() async {
    await Future.wait([
      _loadActivePolls(),
      _loadClosedPolls(),
      _loadMyVotesPolls(),
    ]);
  }

  Future<void> _loadActivePolls() async {
    setState(() => _isLoadingActive = true);
    final res =
        await _api.get('/api/polls', queryParams: {'status': 'active'});
    if (res.isSuccess && res.data != null) {
      final List<dynamic> items =
          res.data!['polls'] ?? res.data!['data'] ?? [];
      setState(() {
        _activePolls = items.cast<Map<String, dynamic>>();
        _isLoadingActive = false;
      });
    } else {
      setState(() {
        _error = res.error;
        _isLoadingActive = false;
      });
    }
  }

  Future<void> _loadClosedPolls() async {
    setState(() => _isLoadingClosed = true);
    final res =
        await _api.get('/api/polls', queryParams: {'status': 'closed'});
    if (res.isSuccess && res.data != null) {
      final List<dynamic> items =
          res.data!['polls'] ?? res.data!['data'] ?? [];
      setState(() {
        _closedPolls = items.cast<Map<String, dynamic>>();
        _isLoadingClosed = false;
      });
    } else {
      setState(() => _isLoadingClosed = false);
    }
  }

  Future<void> _loadMyVotesPolls() async {
    setState(() => _isLoadingMyVotes = true);
    final res =
        await _api.get('/api/polls', queryParams: {'status': 'voted'});
    if (res.isSuccess && res.data != null) {
      final List<dynamic> items =
          res.data!['polls'] ?? res.data!['data'] ?? [];
      setState(() {
        _myVotesPolls = items.cast<Map<String, dynamic>>();
        _isLoadingMyVotes = false;
      });
    } else {
      setState(() => _isLoadingMyVotes = false);
    }
  }

  Future<void> _vote(String pollId, String optionId) async {
    final res = await _api.post('/api/polls/$pollId/vote',
        body: {'option_id': optionId});
    if (res.isSuccess) {
      _loadAllPolls();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote enregistre !'),
            backgroundColor: LinkyColors.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Erreur lors du vote'),
            backgroundColor: LinkyColors.discount,
          ),
        );
      }
    }
  }

  void _showCreatePollModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePollModal(onPollCreated: _loadAllPolls),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPollList(_activePolls, _isLoadingActive,
                      showVoteButton: true),
                  _buildPollList(_closedPolls, _isLoadingClosed,
                      showVoteButton: false),
                  _buildPollList(_myVotesPolls, _isLoadingMyVotes,
                      showVoteButton: false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Neumorphism.button(
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Creer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        color: LinkyColors.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Neumorphism.light(
              borderRadius: 12,
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: LinkyColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Sondages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: LinkyColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showCreatePollModal,
            child: Neumorphism.light(
              borderRadius: 12,
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.add_circle_outline,
                  size: 20, color: LinkyColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: NeuTabBar(
        tabs: const ['Actifs', 'Termines', 'Mes votes'],
        selectedIndex: _tabController.index,
        onTap: (i) {
          setState(() {});
          _tabController.animateTo(i);
        },
      ),
    );
  }

  Widget _buildPollList(List<Map<String, dynamic>> polls, bool isLoading,
      {required bool showVoteButton}) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: LinkyColors.primary));
    }
    if (_error != null && polls.isEmpty) {
      return _buildErrorState();
    }
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.poll_outlined,
                size: 64,
                color: LinkyColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Aucun sondage pour le moment',
              style:
                  TextStyle(color: LinkyColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllPolls,
      color: LinkyColors.primary,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: polls.length,
        itemBuilder: (context, index) =>
            _buildPollCard(polls[index], showVoteButton: showVoteButton),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: LinkyColors.discount),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur',
              style: const TextStyle(color: LinkyColors.textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadAllPolls,
            child: Neumorphism.button(
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Reessayer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              color: LinkyColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll,
      {required bool showVoteButton}) {
    final String id = poll['id']?.toString() ?? '';
    final String question = poll['question'] ?? '';
    final String description = poll['description'] ?? '';
    final String creatorName =
        poll['creator']?['name'] ?? poll['creator_name'] ?? 'Anonyme';
    final String creatorAvatar =
        poll['creator']?['avatar'] ?? poll['creator_avatar'] ?? '';
    final bool isClosed = poll['status'] == 'closed';
    final List<dynamic> options = poll['options'] ?? [];
    final int totalVotes = _calculateTotalVotes(options);
    final String? userVoteId =
        poll['user_vote']?['option_id']?.toString();

    return GestureDetector(
      onTap: () => _showPollDetail(id),
      child: Neumorphism.light(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LinkyColors.textPrimary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LinkyColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: LinkyColors.discount.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Termine',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LinkyColors.discount,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          LinkyColors.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTimeRemaining(poll),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LinkyColors.neonGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: LinkyColors.primaryLight,
                  backgroundImage: creatorAvatar.isNotEmpty
                      ? NetworkImage(creatorAvatar)
                      : null,
                  child: creatorAvatar.isEmpty
                      ? Text(
                          creatorName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  creatorName,
                  style: const TextStyle(
                      fontSize: 12, color: LinkyColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.how_to_vote,
                    size: 14, color: LinkyColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '$totalVotes vote${totalVotes > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: LinkyColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...options.map((option) => _buildOptionRow(
                  option: option,
                  totalVotes: totalVotes,
                  userVoteId: userVoteId,
                  showVoteButton: showVoteButton && !isClosed,
                  pollId: id,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required Map<String, dynamic> option,
    required int totalVotes,
    required String? userVoteId,
    required bool showVoteButton,
    required String pollId,
  }) {
    final String optionId = option['id']?.toString() ?? '';
    final String text = option['text'] ?? '';
    final int votes = option['votes'] ?? 0;
    final double percentage =
        totalVotes > 0 ? (votes / totalVotes) * 100 : 0;
    final bool isSelected = userVoteId == optionId;
    final bool hasVoted = userVoteId != null;

    return GestureDetector(
      onTap: (showVoteButton && !hasVoted)
          ? () => _vote(pollId, optionId)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? LinkyColors.primary.withValues(alpha: 0.08)
              : hasVoted
                  ? LinkyColors.surfaceVariant.withValues(alpha: 0.5)
                  : LinkyColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? LinkyColors.primary.withValues(alpha: 0.4)
                : LinkyColors.border.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: (showVoteButton && !hasVoted)
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFFD1D5DB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 16, color: LinkyColors.primary)
                else if (hasVoted)
                  Icon(Icons.circle_outlined,
                      size: 16, color: LinkyColors.textTertiary)
                else
                  Icon(Icons.radio_button_unchecked,
                      size: 16, color: LinkyColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: LinkyColors.textPrimary,
                    ),
                  ),
                ),
                if (hasVoted) ...[
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? LinkyColors.primary
                          : LinkyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$votes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: LinkyColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
            if (hasVoted) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalVotes > 0 ? votes / totalVotes : 0,
                  backgroundColor: LinkyColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected
                        ? LinkyColors.primary
                        : LinkyColors.primaryLight,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPollDetail(String pollId) async {
    final res = await _api.get('/api/polls/$pollId');
    if (res.isSuccess && res.data != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _PollDetailSheet(poll: res.data!['poll'] ?? res.data!),
      );
    }
  }

  int _calculateTotalVotes(List<dynamic> options) {
    int total = 0;
    for (final option in options) {
      total += (option['votes'] as int?) ?? 0;
    }
    return total;
  }

  String _getTimeRemaining(Map<String, dynamic> poll) {
    final String? endsAt = poll['ends_at'] ?? poll['end_date'];
    if (endsAt == null) return 'Ouvert';
    try {
      final DateTime end = DateTime.parse(endsAt);
      final Duration remaining = end.difference(DateTime.now());
      if (remaining.isNegative) return 'Termine';
      if (remaining.inHours < 24) {
        return '${remaining.inHours}h restantes';
      }
      if (remaining.inDays < 7) {
        return '${remaining.inDays}j restants';
      }
      return DateFormat('dd MMM').format(end);
    } catch (_) {
      return 'Ouvert';
    }
  }
}

class _PollDetailSheet extends StatelessWidget {
  final Map<String, dynamic> poll;

  const _PollDetailSheet({required this.poll});

  @override
  Widget build(BuildContext context) {
    final String question = poll['question'] ?? '';
    final String description = poll['description'] ?? '';
    final String creatorName =
        poll['creator']?['name'] ?? poll['creator_name'] ?? 'Anonyme';
    final List<dynamic> options = poll['options'] ?? [];
    int totalVotes = 0;
    for (final o in options) {
      totalVotes += (o['votes'] as int?) ?? 0;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: LinkyColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LinkyColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LinkyColors.textPrimary,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: LinkyColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: LinkyColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    creatorName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LinkyColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.how_to_vote,
                      size: 14, color: LinkyColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '$totalVotes vote${totalVotes > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LinkyColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...options.map((option) {
                final int votes = option['votes'] ?? 0;
                final double pct =
                    totalVotes > 0 ? (votes / totalVotes) * 100 : 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Neumorphism.light(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option['text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: LinkyColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: LinkyColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$votes',
                              style: const TextStyle(
                                fontSize: 13,
                                color: LinkyColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalVotes > 0 ? votes / totalVotes : 0,
                            backgroundColor: LinkyColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              LinkyColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _CreatePollModal extends StatefulWidget {
  final VoidCallback onPollCreated;

  const _CreatePollModal({required this.onPollCreated});

  @override
  State<_CreatePollModal> createState() => _CreatePollModalState();
}

class _CreatePollModalState extends State<_CreatePollModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _selectedType = 'sondage';
  DateTime? _endsAt;
  bool _isSubmitting = false;

  final Map<String, String> _typeLabels = {
    'sondage': 'Sondage',
    'election': 'Election',
    'concours': 'Concours',
  };

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: LinkyColors.primary,
              onPrimary: Colors.white,
              surface: LinkyColors.surface,
              onSurface: LinkyColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: LinkyColors.primary,
                onPrimary: Colors.white,
                surface: LinkyColors.surface,
                onSurface: LinkyColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      setState(() {
        _endsAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked?.hour ?? 23,
          timePicked?.minute ?? 59,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();

    if (options.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoutez au moins 2 options'),
            backgroundColor: LinkyColors.discount,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final body = <String, dynamic>{
      'question': _questionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'options': options,
    };

    if (_endsAt != null) {
      body['ends_at'] = _endsAt!.toIso8601String();
    }

    final res = await _api.post('/api/polls', body: body);

    setState(() => _isSubmitting = false);

    if (res.isSuccess) {
      widget.onPollCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sondage cree avec succes !'),
            backgroundColor: LinkyColors.neonGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Erreur lors de la creation'),
            backgroundColor: LinkyColors.discount,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: LinkyColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: LinkyColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Creer un sondage',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: LinkyColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Neumorphism.light(
                    borderRadius: 10,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close,
                        size: 18, color: LinkyColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 8),
                  _buildLabel('Question'),
                  const SizedBox(height: 8),
                  _buildNeumorphicTextField(
                    controller: _questionController,
                    hint: 'Posez votre question...',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Description (optionnel)'),
                  const SizedBox(height: 8),
                  _buildNeumorphicTextField(
                    controller: _descriptionController,
                    hint: 'Ajoutez des details...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Type'),
                  const SizedBox(height: 10),
                  _buildTypeSelector(),
                  const SizedBox(height: 20),
                  _buildLabel('Options'),
                  const SizedBox(height: 10),
                  ..._buildOptionFields(),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _addOption,
                    child: Neumorphism.light(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 18, color: LinkyColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter une option',
                            style: TextStyle(
                              color: LinkyColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Date de fin (optionnel)'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectEndDate,
                    child: Neumorphism.light(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: LinkyColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            _endsAt != null
                                ? DateFormat('dd MMMM yyyy HH:mm')
                                    .format(_endsAt!)
                                : 'Choisir une date...',
                            style: TextStyle(
                              fontSize: 14,
                              color: _endsAt != null
                                  ? LinkyColors.textPrimary
                                  : LinkyColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          if (_endsAt != null)
                            GestureDetector(
                              onTap: () => setState(() => _endsAt = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: LinkyColors.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Neumorphism.button(
                    color: LinkyColors.primary,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Publier le sondage',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: LinkyColors.textPrimary,
      ),
    );
  }

  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Neumorphism.light(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      borderRadius: 12,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          color: LinkyColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: LinkyColors.textTertiary,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: _typeLabels.entries.map((entry) {
        final bool isSelected = _selectedType == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? LinkyColors.primary
                    : LinkyColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? LinkyColors.primary
                      : LinkyColors.border,
                  width: isSelected ? 0 : 0.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              LinkyColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFFD1D5DB)
                              .withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                        BoxShadow(
                          color:
                              Colors.white.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(-2, -2),
                        ),
                      ],
              ),
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? Colors.white : LinkyColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildOptionFields() {
    return List.generate(_optionControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildNeumorphicTextField(
                controller: _optionControllers[index],
                hint: 'Option ${index + 1}',
                validator: index < 2
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? 'Champ requis'
                        : null
                    : null,
              ),
            ),
            if (_optionControllers.length > 2) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeOption(index),
                child: Neumorphism.light(
                  borderRadius: 10,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.remove_circle_outline,
                      size: 18, color: LinkyColors.discount),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
