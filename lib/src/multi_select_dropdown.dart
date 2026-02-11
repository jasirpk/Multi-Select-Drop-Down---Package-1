import 'dart:async';
import 'package:flutter/material.dart';

class MultiSelectDropdownServer<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final ValueChanged<List<T>> onChanged;
  final String Function(T) getLabel;
  final bool Function(T, T) compareFn;
  final List<dynamic>? roomIncl;
  final Future<List<T>> Function(String query)? onSearch;
  final Color loadingColor;
  final Color chipBackgroundColor;

  const MultiSelectDropdownServer({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.getLabel,
    required this.compareFn,
    this.roomIncl,
    this.onSearch,
    this.loadingColor = Colors.orange,
    this.chipBackgroundColor = Colors.orange,
  });

  @override
  MultiSelectDropdownServerState<T> createState() => MultiSelectDropdownServerState<T>();
}

class MultiSelectDropdownServerState<T> extends State<MultiSelectDropdownServer<T>> {
  late List<T> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<T> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    if (widget.selectedItems.isNotEmpty) {
      _selectedItems = List.from(widget.selectedItems);
    } else {
      _selectedItems = widget.items.where((item) => (widget.roomIncl ?? []).contains((item as dynamic))).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query, Function setDialogState) async {
    if (query.isEmpty) {
      setDialogState(() {
        _hasSearched = false;
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (widget.onSearch == null) {
      // Fallback to local filtering if no search callback provided
      setDialogState(() {
        _searchResults = widget.items.where((item) {
          final label = widget.getLabel(item).toLowerCase();
          return label.contains(query.toLowerCase());
        }).toList();
        _hasSearched = true;
        _isSearching = false;
      });
      return;
    }

    setDialogState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.onSearch!(query);
      setDialogState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setDialogState(() {
        _isSearching = false;
        _hasSearched = true;
        _searchResults = [];
      });
    }
  }

  void _onSearchChanged(String value, Function setDialogState) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setDialogState(() {
      _searchQuery = value;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value, setDialogState);
    });
  }

  List<T> get _displayItems {
    if (_hasSearched) {
      return _searchResults;
    }
    return widget.items;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      color: Colors.white,
      padding: const EdgeInsets.all(0),
      offset: const Offset(0, 60),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          padding: const EdgeInsets.all(0),
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxHeight: 450),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey.shade50]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.chipBackgroundColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: widget.chipBackgroundColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Select Items',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.chipBackgroundColor),
                        ),
                        const Spacer(),
                        if (_selectedItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: widget.chipBackgroundColor, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${_selectedItems.length} selected',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search bar with enhanced styling
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _searchQuery.isNotEmpty ? widget.chipBackgroundColor.withValues(alpha: 0.3) : Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: widget.chipBackgroundColor.withValues(alpha: 0.7), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _hasSearched = false;
                                      _searchResults = [];
                                      _isSearching = false;
                                    });
                                    _debounce?.cancel();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          _onSearchChanged(value, setDialogState);
                        },
                      ),
                    ),
                  ),

                  const Divider(height: 1, thickness: 1),

                  // List of items with enhanced styling
                  Flexible(
                    child: _displayItems.isEmpty && !_isSearching
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_hasSearched ? Icons.search_off : Icons.keyboard, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _hasSearched ? 'No items found' : 'Type to search...',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _isSearching
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  Text('Searching...', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _displayItems.length,
                            itemBuilder: (context, index) {
                              final item = _displayItems[index];
                              bool isSelected = _selectedItems.any((selectedItem) => widget.compareFn(selectedItem, item));

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? widget.chipBackgroundColor.withValues(alpha: 0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? widget.chipBackgroundColor.withValues(alpha: 0.2) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? widget.chipBackgroundColor : Colors.grey.shade400, width: 2),
                                      color: isSelected ? widget.chipBackgroundColor : Colors.transparent,
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                  ),
                                  title: Text(
                                    widget.getLabel(item),
                                    style: TextStyle(
                                      color: isSelected ? widget.chipBackgroundColor : Colors.black87,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  hoverColor: widget.chipBackgroundColor.withValues(alpha: 0.05),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedItems.removeWhere((selectedItem) => widget.compareFn(selectedItem, item));
                                      } else {
                                        _selectedItems.add(item);
                                      }
                                      widget.onChanged(_selectedItems);
                                    });
                                    setDialogState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      onOpened: () {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _hasSearched = false;
          _searchResults = [];
          _isSearching = false;
        });
        _debounce?.cancel();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: _selectedItems.isNotEmpty ? widget.chipBackgroundColor.withValues(alpha: 0.5) : Colors.grey.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: widget.chipBackgroundColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Select items',
                      style: TextStyle(
                        color: _selectedItems.isEmpty ? Colors.grey.shade600 : widget.chipBackgroundColor,
                        fontSize: 13,
                        fontWeight: _selectedItems.isEmpty ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_drop_down, color: widget.chipBackgroundColor),
              ],
            ),

            // Selected chips
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedItems.map((item) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: widget.chipBackgroundColor.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Chip(
                      surfaceTintColor: Colors.white,
                      backgroundColor: widget.chipBackgroundColor,
                      deleteIconColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      label: Text(
                        widget.getLabel(item),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedItems.removeWhere((selectedItem) => widget.compareFn(selectedItem, item));
                          widget.onChanged(_selectedItems);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
