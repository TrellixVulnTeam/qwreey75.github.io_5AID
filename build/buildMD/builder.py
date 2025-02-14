# Writen by qwreey
# on Aub 29th 2021
#
# gole of this code :
# building markdown to html
# with pymarkdown's tabbed,
# emoji, footnode extensions
#
# it will called by lua (lua node)
#
# uses:
# give json array that includes what you want
# to build, the childrens are has 2 values
# first one, has 'from' index, it will be markdown file
# the last, secound one, has 'to' index, it will be target(output) file (html)

import markdown
import sys
import json

def newInstance() :
    return markdown.Markdown(
        output_format="html5",
        extensions=[
            # 컴포넌트
            'pymdownx.tabbed', # 탭
            'admonition', # 노트라인
            'pymdownx.details', # 더보기(확장 가능한 라벨)
            'pymdownx.progressbar', # 프로그래스 바
            'pymdownx.snippets', # 툴팁, 스니펫 등등
            'attr_list', # ID 붙이기
            'def_list', # 기본 리스트
            'abbr',
            'md_in_html', # html 내부에 마크다운 넣을 수 있도록 만들어줌

            # 기초 설정
            'footnotes', # 바닥글
            'pymdownx.superfences', # 스페이스 관현, 펜스 중첩허용
            'pymdownx.keys', # 단축키(검색)
            'pymdownx.magiclink', # 링크 확장기
            'pymdownx.inlinehilite', # 인라인 코드 하이라이팅
            'pymdownx.highlight', # 코드 구문강조

            # 코드라인 넘버
            'pymdownx.emoji', # 이모지 불러오기
            'pymdownx.tasklist', # 체크박스 불러오기
            'pymdownx.betterem', # 더 나은 글자 서식 알고리즘    
            'pymdownx.smartsymbols', # 특수문자 쉬운입력
            'markdown_include.include', # 다른 md 파일 가져와서 보여주기

            # 기타 세부 설정
            'codehilite', # 코드 언어 추측 끄기
            'toc', # 부분 링크 허용
            'meta' # 메타데이터 관련
        ],
        extension_configs={
            'pymdownx.highlight': {
                'linenums': True
            },
            'pymdownx.emoji': {
                #'emoji_generator': 'python/name:pymdownx.emoji.to_svg'
                #'emoji_index': "python/name:materialx.emoji.twemoji",
                'emoji_generator': "python/name:pymdownx.emoji.to_svg"
            },
            'pymdownx.tasklist': {
                'custom_checkbox': True
            },
            'pymdownx.betterem': {
                'smart_enable': 'all'       
            },


            'pymdownx.smartsymbols':{
                'fractions': False
            },
            'markdown_include.include': {
                'base_path': 'src'
            },
            'codehilite': {
                'guess_lang': False
            },
            'toc': {
                'permalink': True
            }
        }
    )

def buildHtml(infile,outfile):
    markdownInstance = newInstance()
    markdownInstance.reset()
    input_file = open(infile, "r", encoding="utf-8")
    output_file = open(outfile, "w", encoding="utf-8", errors="xmlcharrefreplace")
    this = markdownInstance.convert(input_file.read())
    for key, val in markdownInstance.Meta.items():
        this = "<!--META:" + key + ":" + str(val[0]) + "-->\n" + this
    output_file.write(this)
