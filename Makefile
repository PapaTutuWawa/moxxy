lib/data/generated/providers.g.dart: thirdparty/xmpp-providers/providers-A.json
	python tools/generate_providers.py

thirdparty/xmpp-providers/providers-A.json:
	cd thirdparty/xmpp-providers && python filter.py -A

lib/data/generated/licenses.g.dart: pubspec.yaml
	python tools/generate_licenses.py

.PHONY: data
data: lib/data/generated/providers.dart lib/data/generated/licenses.dart
