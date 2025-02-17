import 'package:flutter/material.dart';
import 'package:minimalist_text2/screens/mode_function.dart'; // Import the new screen

class ModeSelectionSheet extends StatefulWidget {
  final List<Map<String, String>> modes;
  final Function(List<Map<String, String>>) updateModes;

  const ModeSelectionSheet({
    Key? key,
    required this.modes,
    required this.updateModes,
  }) : super(key: key);

  @override
  _ModeSelectionSheetState createState() => _ModeSelectionSheetState();
}

class _ModeSelectionSheetState extends State<ModeSelectionSheet> {
  void _openModeFunctionScreen(String title, String subtitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeFunctionScreen(
          modeTitle: title,
        ),
      ),
    );
  }

  void _addCustomMode() {
    showDialog(
      context: context,
      builder: (context) {
        String newModeTitle = '';
        String newModeSubtitle = '';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.8,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(labelText: 'Mode Title'),
                          onChanged: (value) {
                            newModeTitle = value;
                          },
                        ),
                        TextField(
                          decoration:
                              InputDecoration(labelText: 'Mode Description'),
                          onChanged: (value) {
                            newModeSubtitle = value;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                    context); // Close dialog without saving
                              },
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (newModeTitle.isNotEmpty) {
                                  widget.updateModes([
                                    ...widget.modes,
                                    {
                                      'title': newModeTitle,
                                      'subtitle': newModeSubtitle.isNotEmpty
                                          ? newModeSubtitle
                                          : 'Custom mode.',
                                    }
                                  ]);
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      ...List.generate(widget.modes.length, (index) {
                        return ListTile(
                          leading: Icon(Icons.mode, color: Colors.blue),
                          title: Text(
                            widget.modes[index]['title']!,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            widget.modes[index]['subtitle']!,
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            _openModeFunctionScreen(
                              widget.modes[index]['title']!,
                              widget.modes[index]['subtitle']!,
                            );
                          },
                        );
                      }),
                      ListTile(
                        leading: Icon(Icons.add, color: Colors.green),
                        title: Text(
                          'Add New Mode',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: _addCustomMode,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
