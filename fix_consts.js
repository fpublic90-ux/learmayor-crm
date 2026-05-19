const fs = require('fs');

const errors = `
lib/features/leave/request_leave_screen.dart:628
lib/features/leave/request_leave_screen.dart:638
lib/features/leave/request_leave_screen.dart:642
lib/features/leave/request_leave_screen.dart:681
lib/features/leave/request_leave_screen.dart:683
lib/features/leave/request_leave_screen.dart:860
lib/features/leave/request_leave_screen.dart:867
lib/features/leave/request_leave_screen.dart:925
lib/features/leave/request_leave_screen.dart:930
lib/features/leave/request_leave_screen.dart:983
lib/features/leave/request_leave_screen.dart:986
lib/features/leave/request_leave_screen.dart:1014
lib/features/leave/request_leave_screen.dart:1017
lib/features/leave/request_leave_screen.dart:1044
lib/features/leave/request_leave_screen.dart:1049
lib/features/leave/request_leave_screen.dart:1163
lib/features/leave/request_leave_screen.dart:1166
lib/features/leave/request_leave_screen.dart:1276
lib/features/leave/request_leave_screen.dart:1277
lib/features/leave/my_leave_requests_screen.dart:93
lib/features/leave/my_leave_requests_screen.dart:96
lib/core/widgets/premium_widgets.dart:114
lib/core/widgets/premium_widgets.dart:116
lib/core/widgets/premium_widgets.dart:126
lib/core/widgets/premium_widgets.dart:129
lib/core/widgets/premium_widgets.dart:632
lib/core/widgets/premium_widgets.dart:635
lib/core/widgets/premium_widgets.dart:700
lib/core/widgets/premium_widgets.dart:701
lib/core/widgets/premium_widgets.dart:709
lib/core/widgets/premium_widgets.dart:712
lib/features/settings/branding_screen.dart:96
lib/features/settings/branding_screen.dart:100
lib/features/settings/branding_screen.dart:139
lib/features/settings/branding_screen.dart:140
lib/features/settings/branding_screen.dart:150
lib/features/settings/branding_screen.dart:152
lib/features/settings/branding_screen.dart:170
lib/features/settings/branding_screen.dart:171
lib/features/settings/branding_screen.dart:180
lib/features/settings/branding_screen.dart:184
lib/features/settings/branding_screen.dart:200
lib/features/settings/branding_screen.dart:202
lib/features/settings/branding_screen.dart:214
lib/features/settings/branding_screen.dart:222
lib/features/settings/password_reset_screen.dart:111
lib/features/settings/password_reset_screen.dart:115
`.trim().split('\n');

for (let line of errors) {
  const parts = line.trim().split(':');
  if (parts.length < 2) continue;
  const file = parts[0];
  const lineNum = parseInt(parts[1]) - 1; // 0-indexed
  
  if (!fs.existsSync(file)) continue;
  
  let content = fs.readFileSync(file, 'utf8').split('\n');
  
  // Look backwards from lineNum for the word 'const '
  let found = false;
  for (let i = lineNum; i >= 0 && i >= lineNum - 10; i--) {
    if (content[i].includes('const ')) {
      content[i] = content[i].replace(/const /g, '');
      found = true;
      break;
    }
  }
  
  if (found) {
    fs.writeFileSync(file, content.join('\n'), 'utf8');
    console.log('Fixed in ' + file + ' around line ' + (lineNum + 1));
  }
}
