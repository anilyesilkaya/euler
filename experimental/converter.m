%=== 1. Read in both files
tpl = fileread('templates/post.html');
post = fileread('first_post.html');

%=== 2. Extract the bits you need with regexp (dotall via (?s))
%  — title
toks = regexp(post, '<h1[^>]*>(.*?)</h1>', 'tokens', 'once');
title = toks{1};

%  — date (assuming <time datetime="YYYY-MM-DD">…</time>)
toks = regexp(post, '<time datetime="([^"]+)">.*?</time>', 'tokens', 'once');
date  = toks{1};

%  — author (assuming <span class="author">Name</span>)
toks = regexp(post, '<span[^>]*class="author"[^>]*>(.*?)</span>', 'tokens', 'once');
author = toks{1};

%  — body (everything inside <div class="post-content">…</div>)
toks = regexp(post, '(?s)<div[^>]*class="post-content"[^>]*>(.*?)</div>', 'tokens', 'once');
body = toks{1};

%=== 3. Inject into the template using regexprep
%  (we assume you’ve put literal placeholders like {{title}} in post.html)
out = tpl;
out = regexprep(out, '\{\{\s*title\s*\}\}',    title);
out = regexprep(out, '\{\{\s*date\s*\}\}',     date);
out = regexprep(out, '\{\{\s*author\s*\}\}',   author);
out = regexprep(out, '\{\{\s*body\s*\}\}',     body);

%=== 4. Write the resulting HTML
fid = fopen('first_post_rendered.html','w');
fwrite(fid, out, 'char');
fclose(fid);