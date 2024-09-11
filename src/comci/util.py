from    os  import getcwd
from    pathlib  import Path
import  sys

#   XXX see git_tscript.py for notes about this type problem.
from    pygit2  import *        # type: ignore[import-untyped]
from    pygit2  import (Repository, discover_repository)

####################################################################

#   XXX this really wants to be in a config that we pass around, or
#   perhaps we can just add it to `args`.
PROJECT_ROOT:Path = None       # type:ignore [assignment]

####################################################################
#   File system functions

def find_repo() -> Repository:
    cwd = getcwd()
    debug('cwd:', cwd)
    repo_path = discover_repository(cwd)
    debug('repo_path:', repo_path)
    repo = Repository(repo_path)
    debug('repo:', repo)
    return repo

####################################################################
#   Print and fail functions

def debug(*s):
    return
    print(*s, file=sys.stderr, flush=True)

def fprint(fd, *args):
    print(*args, file=fd, flush=True)

def die(exitcode, *s):
    print(*s, file=sys.stderr, flush=True)
    exit(exitcode)
