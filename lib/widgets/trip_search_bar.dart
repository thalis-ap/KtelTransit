import 'package:flutter/material.dart';
import '../models/stop.dart';

class TripSearchBar extends StatelessWidget {
  final Stop? startStop;
  final Stop? destinationStop;
  final VoidCallback onMenuPressed;
  final VoidCallback onBackPressed;
  final VoidCallback onSwap;
  final Function(bool isStart) onSearch;

  const TripSearchBar({
    super.key,
    required this.startStop,
    required this.destinationStop,
    required this.onMenuPressed,
    required this.onBackPressed,
    required this.onSwap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: (startStop == null && destinationStop == null)
      // 0 stops selected
          ? InkWell(
        onTap: () => onSearch(false), // Default to destination
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuPressed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Αναζήτηση προορισμού...",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.search,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      )
      // 1 or 2 stops selected
          : Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBackPressed,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents layout errors
              children: [
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => onSearch(true),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          startStop?.name ?? "Επιλέξτε αφετηρία...",
                          style: TextStyle(
                            fontSize: 18,
                            color: startStop != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontWeight: startStop != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                InkWell(
                  onTap: () => onSearch(false),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destinationStop?.name ?? "Επιλέξτε προορισμό...",
                          style: TextStyle(
                            fontSize: 18,
                            color: destinationStop != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontWeight: destinationStop != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.swap_vert,
              color: Colors.blue,
            ),
            tooltip: "Αλλαγή κατεύθυνσης",
            onPressed: onSwap,
          ),
        ],
      ),
    );
  }
}