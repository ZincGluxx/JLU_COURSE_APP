import json
from pathlib import Path
from urllib.parse import parse_qs, unquote

HAR_PATH = Path(__file__).with_name('cj.har')


def normalize_post_data(text: str) -> dict:
    if not text:
        return {}
    parsed = parse_qs(text, keep_blank_values=True)
    result = {k: v[0] if len(v) == 1 else v for k, v in parsed.items()}
    if 'requestParamStr' in result and isinstance(result['requestParamStr'], str):
        try:
            result['requestParamStr_decoded'] = json.loads(unquote(result['requestParamStr']))
        except Exception:
            pass
    return result


def main() -> None:
    if not HAR_PATH.exists():
        print(f'未找到 HAR 文件: {HAR_PATH}')
        return

    data = json.loads(HAR_PATH.read_text(encoding='utf-8'))
    entries = data.get('log', {}).get('entries', [])

    post_entries = [
        e for e in entries
        if e.get('request', {}).get('method') == 'POST'
        and '/jwapp/sys/' in e.get('request', {}).get('url', '')
    ]

    grouped = {}
    for e in post_entries:
        req = e.get('request', {})
        res = e.get('response', {})
        content = res.get('content', {})

        url = req.get('url', '')
        grouped.setdefault(url, {
            'count': 0,
            'statuses': set(),
            'post_samples': set(),
            'sizes': [],
            'has_text': False,
        })

        g = grouped[url]
        g['count'] += 1
        g['statuses'].add(res.get('status'))
        g['post_samples'].add(req.get('postData', {}).get('text', ''))
        g['sizes'].append(content.get('size') or 0)
        g['has_text'] = g['has_text'] or bool(content.get('text'))

    print('=== 业务 POST 接口汇总 ===')
    for url in sorted(grouped):
        g = grouped[url]
        print(f'\nURL: {url}')
        print(f'  次数: {g["count"]}')
        print(f'  状态码: {sorted(g["statuses"])}')
        print(f'  响应体大小(最大): {max(g["sizes"]) if g["sizes"] else 0}')
        print(f'  含 response.text: {g["has_text"]}')
        for sample in sorted(g['post_samples']):
            print(f'  POST: {sample}')
            normalized = normalize_post_data(sample)
            if normalized:
                print(f'    参数: {normalized}')


if __name__ == '__main__':
    main()
