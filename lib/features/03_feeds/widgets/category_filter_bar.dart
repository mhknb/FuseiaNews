import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_filter_chip.dart';

class CategoryFilterBar extends StatefulWidget {
  final List<String> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onSelectionChanged;
  final bool showAllOption;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onSelectionChanged,
    this.showAllOption = true,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  @override
  void didUpdateWidget(CategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategories != oldWidget.selectedCategories) {
      _selectedCategories = List.from(widget.selectedCategories);
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    widget.onSelectionChanged(_selectedCategories);
  }

  void _selectAll() {
    setState(() {
      _selectedCategories = List.from(widget.categories);
    });
    widget.onSelectionChanged(_selectedCategories);
  }

  void _clearAll() {
    setState(() {
      _selectedCategories.clear();
    });
    widget.onSelectionChanged(_selectedCategories);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Kategoriler',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.showAllOption) ...[
                TextButton(
                  onPressed: _selectAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Tümü',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Temizle',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = _selectedCategories.contains(category);
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < widget.categories.length - 1 ? 8 : 0,
                  ),
                  child: CategoryFilterChip(
                    category: category,
                    isSelected: isSelected,
                    onTap: () => _toggleCategory(category),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
