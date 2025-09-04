import 'package:flutter/material.dart';
import 'package:travio/services/visit_places_cache_service.dart';
import 'package:travio/utils/utils.dart';

/// Debug widget for managing visit places cache (for development/admin use)
class VisitPlacesCacheDebugWidget extends StatefulWidget {
  const VisitPlacesCacheDebugWidget({
    super.key,
    required this.placeId,
  });

  final String placeId;

  @override
  State<VisitPlacesCacheDebugWidget> createState() =>
      _VisitPlacesCacheDebugWidgetState();
}

class _VisitPlacesCacheDebugWidgetState
    extends State<VisitPlacesCacheDebugWidget> {
  Map<String, dynamic>? _cacheStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await VisitPlacesCacheService.getCacheStats(widget.placeId);
      if (mounted) {
        setState(() {
          _cacheStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      logPrint('❌ Error loading cache stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshCache() async {
    setState(() => _isLoading = true);
    try {
      await VisitPlacesCacheService.refreshCache(placeId: widget.placeId);
      await _loadCacheStats(); // Reload stats
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache refreshed successfully')),
        );
      }
    } catch (e) {
      logPrint('❌ Error refreshing cache: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing cache: $e')),
        );
      }
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _isLoading = true);
    try {
      await VisitPlacesCacheService.clearAllCache();
      await _loadCacheStats(); // Reload stats
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All cache cleared successfully')),
        );
      }
    } catch (e) {
      logPrint('❌ Error clearing cache: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cache: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Visit Places Cache Debug',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_cacheStats != null) ...[
              _buildCacheStatsTable(),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _refreshCache,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Cache'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _clearAllCache,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _loadCacheStats,
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Reload Stats'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsTable() {
    final stats = _cacheStats!;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow('Place ID', widget.placeId),
        _buildTableRow('Cached', stats['cached']?.toString() ?? 'false'),
        _buildTableRow('Place Count', stats['place_count']?.toString() ?? '0'),
        if (stats['cached_at'] != null)
          _buildTableRow('Cached At', _formatDate(stats['cached_at'])),
        if (stats['age_days'] != null)
          _buildTableRow('Age (days)', stats['age_days'].toString()),
        _buildTableRow('Expired', stats['is_expired']?.toString() ?? 'false'),
        if (stats['error'] != null)
          _buildTableRow('Error', stats['error'], isError: true),
      ],
    );
  }

  TableRow _buildTableRow(String key, String value, {bool isError = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            key,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
