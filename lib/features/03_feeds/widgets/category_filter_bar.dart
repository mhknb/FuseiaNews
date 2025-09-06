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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final isSelected = _selectedCategories.contains(category);
            
            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.categories.length - 1 ? 12 : 0,
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
    );
  }
}
