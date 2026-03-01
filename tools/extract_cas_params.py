#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CAS登录辅助脚本 - 从登录页面提取关键参数
"""

import re
import requests
from urllib.parse import urlencode

def get_cas_login_params(service_url='https://iedu.jlu.edu.cn/jwapp/sys/'):
    """
    访问CAS登录页面，提取登录所需的参数
    
    Args:
        service_url: 业务系统URL，登录成功后重定向的地址
        
    Returns:
        dict: 包含lt, execution, 公钥等信息
    """
    # 构造CAS登录URL
    cas_url = f'https://cas.jlu.edu.cn/tpass/login?service={service_url}'
    
    print(f'正在访问CAS登录页面: {cas_url}')
    
    try:
        response = requests.get(cas_url, timeout=10)
        response.raise_for_status()
        html = response.text
        
        # 提取lt (登录票据)
        lt_match = re.search(r'<input[^>]*name="lt"[^>]*value="([^"]+)"', html)
        lt = lt_match.group(1) if lt_match else None
        
        # 提取execution (执行流程ID)
        exec_match = re.search(r'<input[^>]*name="execution"[^>]*value="([^"]+)"', html)
        execution = exec_match.group(1) if exec_match else None
        
        # 提取RSA公钥的modulus
        modulus_match = re.search(r'var\s+modulus\s*=\s*["\']([^"\']+)["\']', html)
        modulus = modulus_match.group(1) if modulus_match else None
        
        # 提取RSA公钥的exponent
        exponent_match = re.search(r'var\s+exponent\s*=\s*["\']([^"\']+)["\']', html)
        exponent = exponent_match.group(1) if exponent_match else None
        
        result = {
            'lt': lt,
            'execution': execution,
            'modulus': modulus,
            'exponent': exponent,
            'cas_url': cas_url,
            'service': service_url,
        }
        
        print('\n=== 提取到的参数 ===')
        for key, value in result.items():
            if value:
                if len(str(value)) > 100:
                    print(f'{key}: {str(value)[:100]}... (共{len(str(value))}字符)')
                else:
                    print(f'{key}: {value}')
            else:
                print(f'{key}: [未找到]')
        
        return result
        
    except requests.RequestException as e:
        print(f'请求失败: {e}')
        return None

def simulate_login(username, password):
    """
    模拟登录流程 (仅演示，实际需要实现RSA加密)
    
    注意: 这个函数只是演示流程，不会真正加密密码
    """
    print('\n=== 模拟登录流程 ===')
    print('步骤 1: 获取登录页面参数')
    
    params = get_cas_login_params()
    if not params or not params['lt'] or not params['execution']:
        print('错误: 无法获取登录参数')
        return False
    
    print('\n步骤 2: RSA加密密码')
    print(f'明文: {username}{password}{params["lt"]}')
    print('注意: 实际应用中需要使用RSA公钥加密该字符串')
    print(f'公钥 modulus: {params["modulus"][:50] if params["modulus"] else "未找到"}...')
    print(f'公钥 exponent: {params["exponent"]}')
    
    print('\n步骤 3: 构造POST数据')
    post_data = {
        'rsa': '[加密后的密码，需要实现RSA加密]',
        'ul': len(username),
        'pl': len(password),
        'sl': 0,
        'lt': params['lt'],
        'execution': params['execution'],
        '_eventId': 'submit',
    }
    
    print('POST参数:')
    for key, value in post_data.items():
        print(f'  {key}: {value}')
    
    print(f'\n步骤 4: POST到 {params["cas_url"]}')
    print('步骤 5: 处理302重定向，提取ticket')
    print('步骤 6: 访问business系统验证ticket')
    print('步骤 7: 保存Cookie，完成登录')
    
    return True

if __name__ == '__main__':
    import sys
    
    print('JLU CAS登录辅助脚本\n')
    
    # 测试不同的service URL
    services = [
        'https://iedu.jlu.edu.cn/jwapp/sys/',  # 教务系统
        'https://i.jlu.edu.cn/up/view?m=up',     # 统一门户
    ]
    
    for service in services:
        print(f'\n{"="*60}')
        print(f'Service: {service}')
        print("="*60)
        get_cas_login_params(service)
        print()
    
    # 如果提供了用户名密码，模拟登录流程
    if len(sys.argv) >= 3:
        username = sys.argv[1]
        password = sys.argv[2]
        simulate_login(username, password)
    else:
        print('\n提示: 运行 python extract_cas_params.py <用户名> <密码> 可以模拟完整登录流程')
