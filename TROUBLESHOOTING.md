## `invalid source release: 17` or `java.lang.StackOverflowError (no error message)`

Building Moxxy requires using JDK 17. If Flutter is not using JDK 17 (which
can happen [when Flutter selects the wrong JDK](https://github.com/flutter/flutter/issues/110807)), then
this error occurs.

Fix: Ensure that Flutter uses the correct JDK version or, as done in
[this issue](https://github.com/PapaTutuWawa/moxxy/issues/15), hardcode the correct JDK path. However,
when using the latter, ensure that this file is not contained in any commits.
