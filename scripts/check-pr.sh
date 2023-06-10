#!/bin/bash
# Run before merging a PR. Checks if the formatting is correct.
# Check if there are any formatting issues
echo "Checking formatting..."
dart format --output none --set-exit-if-changed . &> /dev/null
if [[ ! "$?" = "0" ]]; then
    echo "Error: dart format indicates that format the code is not formatted properly"
    exit 1
fi

# Check if the linter has any issues
echo "Checking linter..."
flutter analyze &> /dev/null
if [[ ! "$?" = "0" ]]; then
    echo "Error: flutter analyze indicates that there are lint issues"
    exit 1
fi

echo "PR looks good!"
