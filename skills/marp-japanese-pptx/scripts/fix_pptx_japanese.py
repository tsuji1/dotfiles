#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import shutil
import sys
import tempfile
import unicodedata
import zipfile

REPLACEMENTS = {
    'lang="zh-CN"': 'lang="ja-JP"',
    'typeface="NotoSansCJKjp"': 'typeface="Noto Sans CJK JP"',
    'typeface="NotoSansMonoCJKjp"': 'typeface="Noto Sans Mono CJK JP"',
    'typeface="DejaVu Sans"': 'typeface="Noto Sans CJK JP"',
    'typeface="YuGothic"': 'typeface="Yu Gothic Medium"',
    'typeface="YuGothic-Medium"': 'typeface="Yu Gothic Medium"',
    'typeface="Times New Roman"': 'typeface="Yu Gothic Medium"',
}


def normalize(path: pathlib.Path) -> None:
    if not path.exists():
        raise FileNotFoundError(path)
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.pptx')
    tmp_path = pathlib.Path(tmp.name)
    tmp.close()
    with zipfile.ZipFile(path, 'r') as zin:
        with zipfile.ZipFile(tmp_path, 'w', zipfile.ZIP_DEFLATED) as zout:
            for info in zin.infolist():
                data = zin.read(info.filename)
                if info.filename.endswith(('.xml', '.rels')):
                    text = unicodedata.normalize('NFKC', data.decode('utf-8'))
                    for before, after in REPLACEMENTS.items():
                        text = text.replace(before, after)
                    data = text.encode('utf-8')
                zout.writestr(info, data)
    shutil.move(tmp_path, path)
    path.chmod(0o644)


def main(argv: list[str]) -> int:
    if not argv:
        print('usage: fix_pptx_japanese.py deck.pptx [deck2.pptx ...]', file=sys.stderr)
        return 2
    for arg in argv:
        path = pathlib.Path(arg).expanduser().resolve()
        normalize(path)
        print(path)
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
