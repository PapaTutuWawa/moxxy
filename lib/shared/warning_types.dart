import 'package:moxxyv2/i18n/strings.g.dart';

const noWarning = 0;
const warningFileIntegrityCheckFailed = 1;

String warningToTranslatableString(int warning) {
  assert(warning != noWarning, 'Calling warningToTranslatableString with noWarning makes no sense');

  switch (warning) {
    case warningFileIntegrityCheckFailed: return t.warnings.message.integrityCheckFailed;
  }

  assert(false, 'Invalid warning code $warning used');
  return '';
}
