#!/bin/bash

echo "=== OpenCode Plugin Test ==="
echo ""

echo "📁 Plugin Files:"
ls -lah ~/.config/opencode/plugin/ 2>/dev/null || echo "❌ Plugin directory not found"
echo ""

echo "📚 Skills Files:"
find ~/.config/opencode/skills -name "SKILL.md" 2>/dev/null || echo "❌ No skills found"
echo ""

echo "📋 Skills Index:"
if [ -f ~/.config/opencode/skills/.index.json ]; then
  cat ~/.config/opencode/skills/.index.json | jq -r '.skills[] | "  - \(.id): \(.title)"' 2>/dev/null || echo "  (jq not available, showing raw)"
  echo "  Total: $(cat ~/.config/opencode/skills/.index.json | jq '.skills | length' 2>/dev/null || echo '?') skills"
else
  echo "  ⚠️  No index file found (will be created on first run)"
fi
echo ""

echo "🔍 Plugin Syntax Check:"
for plugin in ~/.config/opencode/plugin/*.js; do
  if [ -f "$plugin" ]; then
    basename "$plugin"
    node --check "$plugin" 2>&1 && echo "  ✅ Syntax OK" || echo "  ❌ Syntax Error"
  fi
done
echo ""

echo "🚀 Testing OpenCode Start (with logs)..."
echo "   (This will timeout after 3 seconds)"
echo ""
timeout 3 opencode --print-logs . 2>&1 | grep -E "(ERROR|plugin|Skills)" | head -20 || true
echo ""

echo "✅ Test complete!"
echo ""
echo "💡 To manually test with full logs, run:"
echo "   opencode --print-logs --log-level DEBUG"