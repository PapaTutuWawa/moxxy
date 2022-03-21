lib/ui/data/generated/providers.g.dart: thirdparty/xmpp-providers/providers-A.json
	python tools/generate_providers.py

lib/ui/data/generated/licenses.g.dart: pubspec.yaml
	python tools/generate_licenses.py

lib/shared/events.g.dart lib/shared/commands.g.dart: data_classes.yaml
	python tools/generate_data_classes.py

thirdparty/xmpp-providers/providers-A.json:
	cd thirdparty/xmpp-providers && python filter.py -A

.PHONY: data
data: lib/ui/data/generated/providers.g.dart lib/ui/data/generated/licenses.g.dart lib/shared/events.g.dart lib/shared/commands.g.dart
