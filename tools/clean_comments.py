import re
import os

base_path = r'C:\Users\Admin\Desktop\Creative_extended_SP\BasesEnchanted\resources\fivem-greenscreener\images'
files = []

for root, dirs, filenames in os.walk(base_path):
    for f in filenames:
        if f.endswith('.lua') and f != 'clean_comments.py':
            files.append(os.path.join(root, f))

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove block comments --[[ ... ]]
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)

    # Remove inline comments (but not inside strings)
    lines = content.split('\n')
    cleaned_lines = []
    for line in lines:
        in_string = False
        string_char = None
        i = 0
        while i < len(line):
            c = line[i]
            if in_string:
                if c == '\\':
                    i += 2
                    continue
                if c == string_char:
                    in_string = False
            else:
                if c in ['"', "'"]:
                    in_string = True
                    string_char = c
                elif c == '-' and i + 1 < len(line) and line[i + 1] == '-':
                    line = line[:i].rstrip()
                    break
            i += 1
        cleaned_lines.append(line)

    content = '\n'.join(cleaned_lines)

    # Remove triple+ blank lines -> double
    content = re.sub(r'\n{3,}', '\n\n', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Limpo: {os.path.relpath(filepath, base_path)}')

print(f'\nTotal: {len(files)} arquivos limpos.')
