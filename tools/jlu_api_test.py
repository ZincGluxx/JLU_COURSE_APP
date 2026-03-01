"""
吉林大学金智教务系统 API 测试脚本
用于验证 API 接口和数据格式

使用方法:
1. 安装依赖: pip install requests beautifulsoup4
2. 修改下方的配置信息
3. 运行: python jlu_api_test.py
"""

import requests
import json
import urllib3
from typing import Dict, Any, Optional

# 禁用 SSL 警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class JluApiTester:
    def __init__(self, username: str, password: str):
        """
        初始化测试器
        
        Args:
            username: 学号
            password: 密码
        """
        self.session = requests.Session()
        self.base_url = 'https://iedu.jlu.edu.cn'
        self.username = username
        self.password = password
        self.is_logged_in = False
        
        # 常用 Headers
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'zh-CN,zh;q=0.9',
            'X-Requested-With': 'XMLHttpRequest',
        }
    
    def login(self) -> bool:
        """
        登录教务系统 - 尝试多种登录方式
        
        Returns:
            bool: 登录是否成功
        """
        print("\n=== 开始登录流程 ===")
        
        try:
            # 步骤1: 访问主页
            print("1. 访问教务系统主页...")
            home_url = f'{self.base_url}/jwapp/'
            home_resp = self.session.get(home_url, headers=self.headers, verify=False, allow_redirects=True)
            print(f"   状态码: {home_resp.status_code}")
            print(f"   最终 URL: {home_resp.url}")
            print(f"   Cookie: {self.session.cookies.get_dict()}")
            
            # 步骤2: 尝试访问登录页面
            print("\n2. 尝试访问登录页面...")
            
            # 尝试多个可能的登录页面
            login_page_urls = [
                f'{self.base_url}/authserver/login',
                f'{self.base_url}/cas/login',
                f'{self.base_url}/sso/login',
                f'{self.base_url}/jwapp/sys/emapfunauth/pages/funauth/loginAuth.do',
            ]
            
            login_page_url = None
            for url in login_page_urls:
                try:
                    print(f"   尝试: {url}")
                    resp = self.session.get(url, headers=self.headers, verify=False, allow_redirects=True, timeout=5)
                    if resp.status_code == 200:
                        print(f"   ✓ 找到登录页面: {url}")
                        print(f"     最终 URL: {resp.url}")
                        login_page_url = resp.url
                        
                        # 尝试从页面中提取表单信息
                        if '<form' in resp.text:
                            print(f"     页面包含登录表单")
                        break
                except Exception as e:
                    print(f"   ✗ 失败: {e}")
                    continue
            
            if not login_page_url:
                print("\n警告: 未找到登录页面，将尝试直接提交登录")
            
            # 步骤3: 尝试多种登录接口
            print("\n3. 尝试提交登录信息...")
            
            login_urls = [
                f'{self.base_url}/authserver/login',
                f'{self.base_url}/cas/login',
                f'{self.base_url}/sso/doLogin',
                f'{self.base_url}/jwapp/sys/emapfunauth/casValidate.do',
                f'{self.base_url}/jwapp/sys/emapfunauth/pages/funauth/casLoginAuth.do',
            ]
            
            for login_url in login_urls:
                print(f"\n   尝试登录 URL: {login_url}")
                
                # 尝试 application/x-www-form-urlencoded
                login_data = {
                    'username': self.username,
                    'password': self.password,
                    'lt': '',
                    'execution': 'e1s1',
                    '_eventId': 'submit',
                }
                
                try:
                    login_resp = self.session.post(
                        login_url,
                        data=login_data,
                        headers={**self.headers, 'Content-Type': 'application/x-www-form-urlencoded'},
                        verify=False,
                        allow_redirects=True,
                        timeout=10
                    )
                    
                    print(f"   状态码: {login_resp.status_code}")
                    print(f"   最终 URL: {login_resp.url}")
                    print(f"   响应长度: {len(login_resp.text)}")
                    print(f"   Cookie 数量: {len(self.session.cookies)}")
                    
                    if login_resp.status_code == 200:
                        # 检查登录是否成功
                        if 'jwapp' in login_resp.url.lower() and 'login' not in login_resp.url.lower():
                            print(f"   ✓ 登录成功！跳转到了教务系统")
                            self.is_logged_in = True
                            return True
                        
                        # 检查响应内容
                        try:
                            resp_json = login_resp.json()
                            if resp_json.get('code') == '0' or resp_json.get('result') == 'success':
                                print(f"   ✓ 登录成功！")
                                self.is_logged_in = True
                                return True
                        except:
                            pass
                        
                        # 检查是否有错误信息
                        if 'error' in login_resp.text.lower() or '错误' in login_resp.text:
                            print(f"   ✗ 登录失败（页面包含错误信息）")
                            print(f"   响应片段: {login_resp.text[:300]}...")
                        elif login_resp.status_code != 502:
                            # 不是 502 错误，可能是正确的接口但登录失败
                            print(f"   响应片段: {login_resp.text[:500]}...")
                    
                    elif login_resp.status_code == 302:
                        print(f"   收到重定向，可能登录成功")
                        self.is_logged_in = True
                        return True
                    
                except Exception as e:
                    print(f"   ✗ 请求失败: {e}")
                    continue
            
            print("\n✗ 所有登录尝试均失败")
            print("\n" + "="*60)
            print("💡 下一步建议:")
            print("="*60)
            print("请使用浏览器 F12 开发者工具抓包:")
            print("1. 访问 https://iedu.jlu.edu.cn/")
            print("2. 打开 F12 → Network 标签")
            print("3. 勾选 'Preserve log'")
            print("4. 清空记录，然后登录")
            print("5. 找到登录请求（POST 请求）")
            print("6. 右键 → Copy → Copy as cURL")
            print("7. 把复制的内容提供给我")
            print("="*60)
            return False
            
        except Exception as e:
            print(f"\n✗ 登录出错: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def get_courses(self, semester: str = '2024-2025-1') -> Optional[Dict[str, Any]]:
        """
        获取课程表数据
        
        Args:
            semester: 学期代码，如 "2024-2025-1"
        
        Returns:
            dict: 课程表数据，失败返回 None
        """
        if not self.is_logged_in:
            print("未登录，请先登录")
            return None
        
        print("\n=== 获取课程表 ===")
        
        try:
            # 注意：实际的 API 路径可能不同，需要根据抓包结果调整
            course_url = f'{self.base_url}/jwapp/sys/wdkb/modules/xskcb/xskcb.do'
            
            course_data = {
                'XNXQDM': semester,  # 学年学期代码
            }
            
            print(f"请求 URL: {course_url}")
            print(f"请求参数: {course_data}")
            
            resp = self.session.post(
                course_url,
                json=course_data,
                verify=False,
                headers={**self.headers, 'Content-Type': 'application/json'}
            )
            
            print(f"状态码: {resp.status_code}")
            
            if resp.status_code == 200:
                data = resp.json()
                print(f"\n响应数据结构:")
                print(json.dumps(data, indent=2, ensure_ascii=False))
                
                # 保存到文件
                with open('course_data.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                print("\n✓ 数据已保存到 course_data.json")
                
                return data
            else:
                print(f"请求失败: {resp.text}")
                return None
                
        except Exception as e:
            print(f"获取课程表出错: {e}")
            return None
    
    def get_grades(self, semester: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        获取成绩数据
        
        Args:
            semester: 学期代码，为 None 时获取所有学期
        
        Returns:
            dict: 成绩数据，失败返回 None
        """
        if not self.is_logged_in:
            print("未登录，请先登录")
            return None
        
        print("\n=== 获取成绩 ===")
        
        try:
            grade_url = f'{self.base_url}/jwapp/sys/cjcx/modules/cjcx/xscjcx.do'
            
            grade_data = {}
            if semester:
                grade_data['XNXQDM'] = semester
            
            print(f"请求 URL: {grade_url}")
            print(f"请求参数: {grade_data}")
            
            resp = self.session.post(
                grade_url,
                json=grade_data,
                verify=False,
                headers={**self.headers, 'Content-Type': 'application/json'}
            )
            
            print(f"状态码: {resp.status_code}")
            
            if resp.status_code == 200:
                data = resp.json()
                print(f"\n响应数据结构:")
                print(json.dumps(data, indent=2, ensure_ascii=False))
                
                # 保存到文件
                with open('grade_data.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                print("\n✓ 数据已保存到 grade_data.json")
                
                return data
            else:
                print(f"请求失败: {resp.text}")
                return None
                
        except Exception as e:
            print(f"获取成绩出错: {e}")
            return None
    
    def test_all(self):
        """运行所有测试"""
        print("=" * 60)
        print("吉林大学金智教务系统 API 测试")
        print("=" * 60)
        
        # 登录
        if not self.login():
            print("\n测试终止：登录失败")
            return
        
        # 获取课程表
        courses = self.get_courses()
        
        # 获取成绩
        grades = self.get_grades()
        
        print("\n" + "=" * 60)
        print("测试完成！")
        print("=" * 60)
        
        if courses:
            print("\n课程表数据字段:")
            if isinstance(courses.get('data'), list) and len(courses['data']) > 0:
                print(f"  字段列表: {list(courses['data'][0].keys())}")
        
        if grades:
            print("\n成绩数据字段:")
            if isinstance(grades.get('data'), list) and len(grades['data']) > 0:
                print(f"  字段列表: {list(grades['data'][0].keys())}")
        
        print("\n请根据以上输出的字段名更新 Flutter 代码中的字段映射")


def main():
    """
    主函数
    
    使用前请修改下方的学号和密码
    """
    # ============ 配置区域 开始 ============
    USERNAME = 'xinhy1923'  # 修改为你的学号
    PASSWORD = 'wasd12wasd'  # 修改为你的密码
    # ============ 配置区域 结束 ============
    
    if USERNAME == '你的学号' or PASSWORD == '你的密码':
        print("错误：请先在代码中配置你的学号和密码")
        return
    
    # 创建测试器并运行测试
    tester = JluApiTester(USERNAME, PASSWORD)
    tester.test_all()


if __name__ == '__main__':
    main()
