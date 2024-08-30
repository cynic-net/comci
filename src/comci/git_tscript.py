'''

tscript run [-f] COMMIT TEST-SPEC ...                   # cap-commit, background
tscript run [-f] .      TEST-SPEC ...                   # cap-files,  background
tscript run   -i COMMIT TEST-SPEC ... -- test-args      # cap-none,   foreground
tscript run   -i .      TEST-SPEC ... -- test-args      # cap-none,   foreground
tscript show ...
tscript list ... # ?

Consider later making `COMMIT` optional, defaulting to HEAD.

Though we say COMMIT above, results are stored indexed by the tree to which
that commit points. Two different commits with the same tree will have the
same results.

'''
from    argparse  import ArgumentParser, Namespace
from    functools  import partial as par
from    os  import chdir, getcwd
from    pathlib  import Path
from    stat  import S_IXUSR
from    subprocess  import run, DEVNULL

#   Pytest replaces `sys.stdout` and `sys.stderr` for the duration of
#   a test when we're using the `capsys` fixture, so we need to read the
#   value from `sys` _after_ the test has started, rather than when we're
#   imported at collection time.
import  sys

#   XXX A `py.typed` was added to pygit2 in the commit just after the
#   1.15.1 release. The type:ignore below should be removed as soon
#   as the next release is out and we can upgrade.
#   (Also, don't understand how mypy thinks Repository and
#   discover_repository() don't come in with the `*` import, but this
#   will go away anyway once we get a py.typed version.)
from    pygit2  import *        # type: ignore[import-untyped]
from    pygit2  import (Repository, discover_repository)


####################################################################
#   Main

PROJECT_ROOT    :Path
REPO            :Repository

def main(command_line_args=None):
    global PROJECT_ROOT, REPO
    args = parseargs(command_line_args)
    REPO = find_repo()
    PROJECT_ROOT = Path(REPO.path).parent
    chdir(PROJECT_ROOT)
    args.cmd(args)

def command_run(args):
    die(9, 'XXX Write me!')
    for ts in tscripts(PROJECT_ROOT):
        #   XXX in both cases here we should be dealing with the optional
        #   single argument to the test(s) somehow?
        if args.interactive:
            run_ts_interactive(ts, arg=None)
        else:
            run_ts_capture(ts, arg=None, foreground=args.foreground)

def parseargs(command_line_args):
    top_parser = ArgumentParser(description='''
        Summary of what this program does.
        And details on further lines.''',
        epilog='Text after options are listed')
    sub = top_parser.add_subparsers(required=True)

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
        help='or `.` for working copy')
    ra('TESTSPEC', nargs='*',
        help='0 or more `tname`, `tname,param,param`')

    show_parser = sub.add_parser('show', help='XXX show')
    show_parser.set_defaults(cmd=par(unimpl_command, 'show'))

    list_parser = sub.add_parser('list', help='XXX list')
    list_parser.set_defaults(cmd=par(unimpl_command, 'show'))

    return top_parser.parse_args(command_line_args)

def unimpl_command(name, args):
    die(9, f'unimplemented command: {name}')

####################################################################
#   Run single tests.

def run_ts_interactive(ts, arg=None):
    ''' Run test scripts in "interactive" mode, witing for tests to complete
        and stopping at the first failure. These are run against the actual
        working tree with the stdin/stdout/stderr of this process. The exit
        code is 0 for success or the exit code of the test script that failed.
    '''
    ec = run_ts(ts, arg, inherit_stdin=True)
    if ec != 0: exit(ec)

def run_ts_capture(ts, arg=None, foreground=False):
    ''' Run all test scripts in "background" mode, capturing output and
        and failure status of each one. These are run against a copy of
        the working tree.

        XXX capture output

        • stdin is always ``/dev/null``.
        • stdout and stderr are captured in
          ``.build/tscript/out/TS.ARG.{out,err}``
    '''
    #   This should set up the output to be captured into the repo
    #   (or files if working copy is modified) and then run the
    #   test in the background, not waiting for completion.
    #   XXX 2. test failure when working copy not modified (fails because
    #          we don't yet write to Git repo
    #   XXX 3. implement background running
    #   XXX 4. implement capture to repo commit

    outpath = output_path(ts, arg, 'out')
    errpath = output_path(ts, arg, 'err')

    ec = run_ts(ts, arg, io=(outpath, errpath))
    fprint(sys.stdout, 'git-tscript: {}{} completed (exit={})'.format(
        ts.name, ' ' + arg if arg else '', ec))

def output_path(ts, arg, suffix):
    if arg is None: arg = ''
    fname = '.'.join([ts.name, arg, suffix])
    return PROJECT_ROOT / '.build' / 'tscript' / 'out' / fname

def run_ts(ts, arg=None, inherit_stdin=False, io=(None, None)):
    ''' Run the test script at path `ts`, with optional argument `arg`
        (default `None`). A test header will be logged to the standard
        output (whether inherited or captured), and also a failure message
        if the `ts` exit code is anything other than 0.

        * `inherit_stdin` is either `True` to let the tscript read from
          this process' `stdin`, or `False` to have `stdin` return EOF on
          read.
        * `io` is a tuple indicating the destination of stdout and stderr.
          The value `None` indicates the tscript should inherit the
          descriptors from this process, otherwise the value should be a
          `Path` to which the output will be written. (This is called
          "capture" mode.)

        The exit code of the tscript is returned.
    '''
    def openf(i):
        if i is None: return None
        i.parent.mkdir(parents=True, exist_ok=True)
        fd = i.open('w', buffering=- 1, encoding='UTF-8')
        return fd
    iof = tuple(openf(i) for i in io )

    header_fd = iof[0];
    if header_fd is None: header_fd = sys.stdout
    if arg is None:
        command = [ts]
        fprint(header_fd, f'━━━━━━━━━━━━ {ts.name}')
    else:
        command = [ts, arg]
        fprint(header_fd, f'━━━━━━━━━━━━ {ts.name} {arg}')

    debug('io:', io)
    stdin = None if inherit_stdin else DEVNULL
    ec = run(command, stdin=stdin, stdout=iof[0], stderr=iof[1]).returncode
    if ec != 0: fprint(header_fd, f'━━━━━ FAILED (exitcode={ec})')
    for i in iof:
        if i is not None: i.close()
    return ec

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

def tscripts(project_root):
    for pts in sorted(project_root.glob('tscript/*')):
        is_exec = pts.stat().st_mode & S_IXUSR
        if not pts.is_file() or not is_exec: continue
        yield pts

####################################################################
#   Print and fail functions

def debug(*s):
    return
    print(*s, file=sys.stderr, flush=True)

def fprint(fd, *args):
    print(*args, file=fd, flush=True)

def die(exitcode, *s):
    print(*s, file=sys.stderr, flush=True)
    print( 'XXX exitcode:', exitcode, file=sys.stderr, flush=True)
    exit(exitcode)
