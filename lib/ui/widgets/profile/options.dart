import 'package:flutter/material.dart';

class ProfileOption {
  const ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.description,
  });
  final IconData icon;
  final String title;
  final String? description;
  final void Function() onTap;
}

class ProfileOptions extends StatelessWidget {
  const ProfileOptions({
    required this.options,
    super.key,
  });
  final List<ProfileOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
        .map((option) => InkWell(
          onTap: option.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    option.icon,
                    size: 32,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.headline6,
                    ),

                    if (option.description != null)
                      Text(
                        option.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),).toList(),
    );
  }
}
