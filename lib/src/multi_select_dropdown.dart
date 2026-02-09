import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    Key? key,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.getLabel,
    required this.compareFn,
    this.roomIncl,
    this.onSearch,
    this.loadingColor = Colors.orange,
    this.chipBackgroundColor = Colors.orange,
  }) : super(key: key);

  @override
  _MultiSelectDropdownServerState<T> createState() => _MultiSelectDropdownServerState<T>();
}

class _MultiSelectDropdownServerState<T> extends State<MultiSelectDropdownServer<T>> {
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
      _selectedItems = widget.items
          .where((item) =>
          (widget.roomIncl ?? []).contains((item as dynamic)))
          .toList();
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
      elevation: 10,
      itemBuilder: (context) => [
        PopupMenuItem(
          padding: const EdgeInsets.all(0),
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.chipBackgroundColor)
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        _onSearchChanged(value, setDialogState);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // List of items
                  Flexible(
                    child: _displayItems.isEmpty && !_isSearching
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _hasSearched
                              ? 'No items found'
                              : 'Type to search...',
                        ),
                      ),
                    )
                        : _isSearching
                        ?  Center(
                      child: Padding(
                        padding:  EdgeInsets.all(8.0),
                        child: SpinKitPulsingGrid(
                          color: widget.loadingColor,
                          size: 30.0,
                        ),
                      ),
                    ):
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _displayItems.length,
                      itemBuilder: (context, index) {
                        final item = _displayItems[index];
                        bool isSelected = _selectedItems.any(
                                (selectedItem) =>
                                widget.compareFn(selectedItem, item));

                        return ListTile(
                          tileColor: Colors.transparent,
                          title: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                                widget.getLabel(item),
                                style: const TextStyle(color: Colors.black, fontSize: 16)
                            ),
                          ),
                          trailing: isSelected
                              ? const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 15,
                            ),
                          )
                              : null,
                          hoverColor: Colors.grey.withOpacity(0.3),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.removeWhere(
                                        (selectedItem) => widget.compareFn(
                                        selectedItem, item));
                              } else {
                                _selectedItems.add(item);
                              }
                              widget.onChanged(_selectedItems);
                            });
                            setDialogState(() {});
                          },
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
        padding: const EdgeInsets.all(9.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(3),
        ),
        child:

        Wrap(
          spacing: 8.0,
          runSpacing: 8,
          children: [
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select items',style: TextStyle(color: Colors.grey,fontSize: 12),)),
            ..._selectedItems.map((item) {
              return Chip(
                surfaceTintColor: Colors.white,
                backgroundColor: widget.chipBackgroundColor,
                deleteIconColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                  side: const BorderSide(color: Colors.transparent),
                ),
                label: FittedBox(
                  child: Text(
                    widget.getLabel(item),
                    overflow: TextOverflow.visible,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                onDeleted: () {
                  setState(() {
                    _selectedItems.removeWhere((selectedItem) =>
                        widget.compareFn(selectedItem, item));
                    widget.onChanged(_selectedItems);
                  });
                },
              );
            }).toList(),
            const Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.arrow_drop_down),
            ),
          ],
        ),
      ),
    );
  }
}