'''
'''
from    argparse  import ArgumentParser
from    functools  import partial as par
from    importlib.metadata  import version
from    os  import chdir
from    pathlib  import Path

#   XXX A `py.typed` was added to pygit2 in the commit just after the
#   1.15.1 release. The type:ignore below should be removed as soon
#   as the next release is out and we can upgrade.
#   (Also, don't understand how mypy thinks Repository and
#   discover_repository() don't come in with the `*` import, but this
#   will go away anyway once we get a py.typed version.)
from    pygit2  import *        # type: ignore[import-untyped]
from    pygit2  import Repository

from    comci.run  import command_run
from    comci.util  import PROJECT_ROOT     # XXX remove; see comci.util
from    comci.util  import die, find_repo

####################################################################
#   Main

def main(command_line_args=None):
    args, parser = parseargs(command_line_args)
    if args.version:
        print(f'{parser.prog} version {version(parser.prog)}')
        return
    elif not hasattr(args, 'cmd'):
        parser.error('command must be specified')

    global PROJECT_ROOT
    PROJECT_ROOT = Path(find_repo().path).parent
    chdir(PROJECT_ROOT)
    args.cmd(args)

def parseargs(command_line_args):
    top_parser = ArgumentParser(description='''
        Summary of what this program does.
        And details on further lines.''',
        epilog='Text after options are listed')

    top_parser.add_argument('--version', action='store_true',
        help='show program version information')

    sub = top_parser.add_subparsers()

    run_parser = sub.add_parser('run', help='XXX run')
    run_parser.set_defaults(cmd=command_run)
    ra = run_parser.add_argument
    ra('-R', '--rerun', action='store_true',
        help='Run tests on a commit even when we already have test results stored')
        # overwrites previous results
    ra('-f', '--foreground', action='store_true',
        help='Wait for all tests to complete before returning.')
    ra('-i', '--interactive', action='store_true',
        help='Run tests in foreground sending output to the terminal.')
        # sets -f and -R
    ra('TARGET',
        help='tree-ish or `.` for working copy')
    ra('TESTSPEC', nargs='*',
        help='optional `tname`/`tname,param,…` arguments')

    show_parser = sub.add_parser('show', help='XXX show')
    show_parser.set_defaults(cmd=par(unimpl_command, 'show'))

    list_parser = sub.add_parser('list', help='XXX list')
    list_parser.set_defaults(cmd=par(unimpl_command, 'show'))

    return top_parser.parse_args(command_line_args), top_parser

def unimpl_command(name, args):
    die(9, f'unimplemented command: {name}')

