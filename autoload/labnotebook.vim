" Vim plug-in
" Laboratory Notebook plugin
" Version: 0.2
" Author: Guillaume T Vallet <gtvallet[a]gmail.com>
" Created: 2014-07-20
" Last change: 2015-06-20

function! labnotebook#EditConf()
python << endOfPython
fconf = '~/.labnotebook.conf'
vim.command("e %s" % fconf)
endOfPython
endfunction


function! labnotebook#SelectProject(todo)
python << endOfPython
def get_settings():
    """ Read the name and the path of the projects.
    """
    cfg = open(os.path.join(os.path.expanduser('~'), ".labnotebook.cfg"))
    settings = yaml.load(cfg)
    # Define some global variables about the main settings
    vim.command('let s:author = %s' % [settings['author']])
    vim.command('let s:proj_path = %s' % [settings['projects_path']])
    vim.command('let s:lnb = %s' % [settings['lnb_folder']])
    return settings['projects']

def select_project(todo, projects):
    """ Create a list to select the project to use.
    """
    vim.command('let g:projects=%s' % [proj['code'] for proj in projects])
    if todo == 'note':
        select = [ 'Select a project or create a new one: ' ]
        select.append('0. Add a new project')
    else:
        select = [ 'Select a project: ' ]
    for n, proj in enumerate(projects):
        select.append(str(n+1) + '. ' + proj['code'])
    select.append(str(len(projects)+1) + '. Cancel')
    return select

# Main script -- Run the functions to select the project to use
todo = vim.eval('a:todo')
projects = get_settings()
choices = select_project(todo, projects)
vim.command('let a:choice = inputlist(%s)' % choices)
if todo == 'note':
    if vim.eval('a:choice') == '0':
        vim.command('call labnotebook#CreateNoteBook()')
    elif vim.eval('a:choice') == len(choices):
        vim.command('close')
    else:
        project = projects[int(vim.eval('a:choice'))-1]
        vim.command('call labnotebook#EditNote(%s)' % project)
else:
    project = projects[int(vim.eval('a:choice'))-1]
    vim.command('let g:project = %s' % project)

endOfPython
endfunction


function! labnotebook#UpdateNote()
python << endOfPython
today = strftime("%Y-%m-%d")
# Extract the content of the buffer
content = "\n".join(vim.current.buffer[:])
# Extract the note head from the content
head_pattern = re.compile(r"^(\"-+\n.*)(LAST CHANGE:\s+)(\d{4}-\d{2}-\d{2})(.*\"-+\n)", re.DOTALL)
head = re.search(head_pattern, content).group(0)
# Update the last change date to the current date
head = re.sub(head_pattern, r"\g<1>\g<2>%s\g<4>" % today , head)
# Send the update version of the head note to the buffer
start = content.count("\n",0,re.search(head_pattern, content).start())
end = content.count("\n",0,re.search(head_pattern, content).end())
vim.current.buffer[start:end] = head.split("\n")[0:-1]
# Write the new content and commit the change
#vim.command("Gwrite")
#vim.command("Gcommit -am '%s %s modifications'" % (vim.eval('g:project'), today))
endOfPython
endfunction


function! labnotebook#EditNote(project)
python << endOfPython
def edit_note(project, title, fnote):
    """ Create a new note base on the current date and project name.
    """
    header = ['"' + 79*'-']
    header.append('"')
    header.append('"   TITLE:      %s' % title)
    header.append('"   AUTHOR:     %s' % vim.eval('s:author')[0])
    header.append('"   CODE:       %s' % project['code'])
    header.append('"   PROJECT:    %s' % project['title'])
    header.append('"')
    header.append('"   CREATED:        %s' % strftime("%Y-%m-%d"))
    header.append('"   LAST CHANGE:    %s' % strftime("%Y-%m-%d"))
    header.append('"')
    header.append('"   KEYWORDS:   %s' % "; ".join(sorted(project['tags'])))
    header.append('"')
    header.append('"' + 79*'-')
    header.append('')
    header.append('# ')
    with open(fnote, 'w') as outfile:
        outfile.write("\n".join(header))
    vim.command("e %s" % fnote)
    vim.current.window.cursor = (15,3)

def get_note(project, title):
    notename = project['code'] + "_" + strftime("%Y-%m-%d") + ".lab"
    fnote = os.path.join(vim.eval('s:proj_path')[0], project['folder'], 
                         vim.eval('s:lnb')[0], notename)
    edit_note(project, title, fnote)

def prompt(message=""):
    vim.command('call inputsave()')
    vim.command("let user_input = input('" + message + ": ')")
    vim.command('call inputrestore()')
    return vim.eval('user_input')

title = prompt("Enter the note title")
get_note(vim.eval('a:project'), title)

endOfPython
endfunction


function! labnotebook#CreateNoteBook()
python << endOfPython

def project_writer(project):
    cfg_file = os.path.join(os.path.expanduser('~'), ".labnotebook.cfg")
    settings = yaml.load(open(cfg_file))
    settings['projects'].append(project) 
    with open(cfg_file, 'w') as cfg:
        yaml.dump(settings, cfg, default_flow_style=False, indent=2, allow_unicode=True)

def check_project_exist(code):
    """ Check if the proposed name of the project already exist.
         If so, return True.
    """
    if code in vim.eval('g:projects'):
        return True

def prompt(message=""):
    vim.command('call inputsave()')
    vim.command("let user_input = input('" + message + ": ')")
    vim.command('call inputrestore()')
    return vim.eval('user_input')

def add_notebook():
    """ Create a new invisible folder where notes will be stored.
        When a new notebook is created, the function will store the name and 
          path of the project in a configuration file.
    """
    # Get the code of the project
    code = prompt("Enter the code of the project ")
    while check_project_exist(code):
        code = prompt("This code is already used. Please enter a new project code")
    title = prompt("Enter the title of the project ")
    # Get the name of the authors
    authors = prompt("Enter the authors associate with the project (separated by ,)")
    # Get the tags
    tags = prompt("Enter the keywords of the projects (separated by ,)")
    # Get the path to the folder
    folder = prompt("Enter the name of the folder within the project path \
(default %s)" % vim.eval('s:proj_path')[0])
    # Create the folder in the current directory or in the provided path
    new_fold = os.path.join(vim.eval('s:proj_path')[0], folder,
                                vim.eval('s:lnb')[0])
    if not os.path.exists(new_fold):
        os.makedirs(new_fold)
    project = {'title': title, 'code': code, 'folder': folder,
                'authors': authors.split(","), 'tags': tags.split(",")}
    # Write the name and path of the new project in the configuration file
    project_writer(project)
    vim.command("cd %s" % new_fold)
    vim.command('call labnotebook#EditNote(%s)' % project)

add_notebook()

endOfPython
endfunction


function! labnotebook#SearchNote(...)
python << endOfPython
def listNotes(project):
    notes_path = os.join(vim.eval('s:proj_path')[0], project['folder'], 
                        vim.eval('s:lnb')[0])
    notes = [f for f in os.listdir(notes_path) if f.endswith('.lab')]
    titles = []
    for note in notes:
        txt = open(os.path.join(notes_path, note)).readlines()
        titles.append(re.search(r"TITLE:\s+(.*)", "".join(txt)).group(1))
    choices = [str(i+1) + ". %s -- %s" % (titles[i], n) for i,n in enumerate(notes)] 
    # Delete the current buffer
    vim.command('redraw')
    # Select the note to display 
    select_txt = ["Please select a note to edit:"] 
    vim.command('let a:choice = inputlist(%s)' % (select_txt + choices + ["",""]))
    # Display the selected note in a new buffer
    note = notes[int(vim.eval('a:choice'))-1]
    vim.command("e %s" % (os.path.join(notes_path, note)))

def searchInNotes(pattern, project):
    vim.command('vimgrep "%s" %s/*.lab' % (pattern, project['path']))

# Define the current project
vim.command("call labnotebook#SelectProject('search')")
# Check if an argument is provided
if vim.eval('a:0') == '0':
    # If no argument, display the list of notes
    listNotes(vim.eval('g:project'))
else:
    # Use the argument provided as search pattern
    searchInNotes(vim.eval('a:1'), vim.eval('g:project')) # Else list all the notes 

endOfPython
endfunction
            

function! labnotebook#StartNoteBook(...)
" Check if an argument is provided
if a:0
    " Open the configuration file if argument is conf
    if a:1 == 'conf'
       call labnotebook#EditConf()
    endif
" If no argument is provided, run the main script
else
 call labnotebook#SelectProject('note')
endif
endfunction


function! labnotebook#ExportNotes(output)
python << endOfPython

import glob
from subprocess import call

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

# FIXME add tags, project title and authors
def create_template(code):
    today = strftime("%Y-%m-%d")
    header  = "% {0}\n".format(code)
    header += "% {0}\n".format(vim.eval('s:author')[0])
    header += "% {0}\n".format(today)
    with open(fmd, 'w+') as fnote:
        fnote.write(header)

def notify(project, output='html'):
    # Define the project's directory as the working directory
    project_dir = os.path.join(vim.eval('s:proj_path')[0], project['folder'], 
                        vim.eval('s:lnb')[0])
    os.chdir(project_dir)
    # Get all the lab files inside that directory
    notes = sorted(glob.glob('*.lab'))
    if len(notes) < 1:
        print("No note to compile into a notebook")
        return
    create_template(project['code'])
    # Extract content of each note and transform it to markdown format
    for note in notes:
        data = get_content(note)
        head_note = "\n\n# %s \n\n" % data['title']
        img = os.path.join(os.path.expanduser('~'), '.vim/plugin/labnotebook/templates/')
        dtt = datetime.datetime.strptime( data['creation'], '%Y-%m-%d') 
        if data['last_change'] != data['creation']:
            head_note += "<div class='notedate'> <p class='calendar'>%s <span>%s</span></p> <span class='year'> %s </span> </div>\n<div class='latestchg'>Dernières modifications: %s</div>" % (dtt.day, dtt.strftime("%b"), dtt.year, data['last_change'])
                #head_note += "<span class='notedate'> <span class="year">%s</span> <span class="month">%s</span> <span class="day"> %s </span></span>\n" % (dtt.year, dtt.strftime("%b"), dtt.day)
        else:
            head_note += "<div class='notedate'> <p class='calendar'>%s <span>%s</span></p> <span class='year'> %s </span> </div>\n" % (dtt.day, dtt.strftime("%b"), dtt.year)
            #if output == 'html':
            #head_note = "\n\n# " + head_note + "\n</span>\n\n"
        with open(fmd, 'a+') as fnote:
            fnote.write("<article class='note'>")
            fnote.write(head_note)
            fnote.write(data['content'])
            fnote.write("</article>")
    if output == 'html':
        template = 'labnote.html'
    file = os.path.join(os.path.expanduser('~'), '.vim/plugin/labnotebook/templates/')
    call(['pandoc', '-s', '-S', 'notebook.md', '-o', '../%s-notebook.html' % project['code'], '--toc', '--toc-depth=1', '--template=%s%s' % (file, template)])
    call(['sed', '-i', '0,/<ul>/s//<ol>/', '../%s-notebook.html' % project['code']])
    call(['sed', '-i', '0,/<\/ul>/s//<\/ol>/', '../%s-notebook.html' % project['code']])
    vim.command("redraw")
    print('\nNotes successfully exported to %s-notebook.hml\n' % project['code'])

fmd = 'notebook.md'
vim.command("call labnotebook#SelectProject('search')")
notify(vim.eval('g:project'), vim.eval('a:output'))

endOfPython
endfunction
