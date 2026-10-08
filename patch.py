import json
import re

file_path = '3_COD_Panel creation.ipynb'

with open(file_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code':
        source = ''.join(cell['source'])
        if 'def split_and_export(' in source:
            # Replace the mask_11 definition
            new_source = source.replace(
                'mask_11 = panel["ICFES_DISPONIBLE_REF"].eq(1)',
                'sedes_11 = panel.loc[panel["ICFES_DISPONIBLE_REF"].eq(1), "SEDE_CODIGO"].unique()\n    mask_11 = panel["SEDE_CODIGO"].isin(sedes_11)'
            )
            
            # Write back
            lines = [line + '\n' for line in new_source.split('\n')]
            if lines[-1] == '\n':
                lines.pop()
            else:
                lines[-1] = lines[-1].rstrip('\n')
            
            cell['source'] = lines
            print('Found and replaced split_and_export.')
            break

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1, ensure_ascii=False)

print('Notebook patched successfully.')

