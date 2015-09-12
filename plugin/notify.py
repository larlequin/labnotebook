#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import os
import glob
from time import strftime
from subprocess import call

author = 'GT Vallet'

fmd = 'notebook.md'

def change_mdheading(content):
    if re.search(r"#{1}", content):
        for lvl in range(5,0,-1):
            pattern = re.compile(r'[^#]#{%s}[^#]' % lvl)
            subs = "\n" + '#' * (lvl+1) + " "
            content = re.sub(pattern, subs, content)
    return content

def extract_head(heading):
    title = re.search(r"TITLE:\s+(.*)", heading).group(1)
    creation = re.search(r"CREATED:\s+(.*)", heading).group(1)
    last_modif = re.search(r"LAST CHANGE:\s+(.*)", heading).group(1)
    return {'title': title, 'creation': creation, 'last_change': last_modif}

def get_content(note):
    head_pattern = re.compile(r"^\"-+\n(.*)\"-+", re.DOTALL)
    fnote = open(note).readlines()
    head = re.search(head_pattern, "".join(fnote)).group(1)
    body = fnote[head.count('\n')+2:]
    body = change_mdheading("".join(body))
    data = extract_head(head)
    data['content'] = body
    return data 

def create_template(project, author):
    today = strftime("%Y-%m-%d")
    header  = "% {0}\n".format(project)
    header += "% {0}\n".format(author)
    header += "% {0}\n".format(today)
    with open(fmd, 'w+') as fnote:
        fnote.write(header)

def notify(project, output='html'):
    # Define the project's directory as the working directory
    os.chdir(project['path'])
    # Get all the lab files inside that directory
    notes = glob.glob('*.lab')
    if len(notes) < 1:
        print("No note to compile into a notebook")
        return
    create_template(project['name'], 'GT Vallet')
    # Extract content of each note and transform it to markdown format
    for note in notes:
        data = get_content(note)
        head_note = "<span class='notetitle'> %s </span>" % data['title']
        head_note += "<span class='datecrea'> %s </span>" % data['creation']
        if data['last_change'] != data['creation']:
            head_note += "<span class='update'> (%s) </span>" % data['last_change']
        if output == 'html':
            head_note = "\n\n# " + head_note + "\n</span>\n\n"
        with open(fmd, 'a+') as fnote:
            fnote.write("<article class='note'>")
            fnote.write(head_note)
            fnote.write(data['content'])
            fnote.write("</article>")

    call(['pandoc', '-s', '-S', 'notebook.md', '-o', 'notebook.html', '--toc', '--template=template.html', '--css=style.css'])
