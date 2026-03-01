#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""分析登录HAR文件，提取CAS认证流程"""

import json
import sys
from urllib.parse import parse_qs, urlparse, unquote

def analyze_login_har(har_file):
    with open(har_file, 'r', encoding='utf-8') as f:
        har = json.load(f)
    
    entries = har['log']['entries']
    print(f'总请求数: {len(entries)}\n')
    
    print('=== 所有请求概览 ===')
    for i, entry in enumerate(entries, 1):
        method = entry['request']['method']
        url = entry['request']['url']
        status = entry['response']['status']
        print(f'{i}. [{method}] [{status}] {url}')
    
    print('\n=== POST请求详情 ===')
    for i, entry in enumerate(entries, 1):
        if entry['request']['method'] == 'POST':
            url = entry['request']['url']
            status = entry['response']['status']
            print(f'\n--- POST #{i} ---')
            print(f'URL: {url}')
            print(f'状态码: {status}')
            
            # 请求头
            headers = {h['name']: h['value'] for h in entry['request']['headers']}
            if 'Content-Type' in headers:
                print(f'Content-Type: {headers["Content-Type"]}')
            if 'Cookie' in headers:
                print(f'Cookie: {headers["Cookie"][:150]}...')
            
            # POST数据
            if 'postData' in entry['request']:
                post_data = entry['request']['postData']
                if 'text' in post_data:
                    text = post_data['text']
                    print(f'POST Body: {text}')
                    
                    # 解析表单数据
                    if 'application/x-www-form-urlencoded' in post_data.get('mimeType', ''):
                        try:
                            params = parse_qs(text)
                            print('解析后的参数:')
                            for key, values in params.items():
                                for val in values:
                                    if len(val) > 200:
                                        print(f'  {key}: {val[:200]}...(共{len(val)}字符)')
                                    else:
                                        print(f'  {key}: {val}')
                        except:
                            pass
            
            # 响应
            response = entry['response']
            print(f'响应大小: {response["content"]["size"]} bytes')
            if 'text' in response['content'] and response['content']['text']:
                resp_text = response['content']['text'][:500]
                print(f'响应内容(前500字符): {resp_text}')

if __name__ == '__main__':
    har_file = sys.argv[1] if len(sys.argv) > 1 else 'tools/login.har'
    analyze_login_har(har_file)
