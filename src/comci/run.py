' ``run`` command '

from    stat  import S_IXUSR
from    subprocess  import run, DEVNULL

#   Pytest replaces `sys.stdout` and `sys.stderr` for the duration of
#   a test when we're using the `capsys` fixture, so we need to read the
#   value from `sys` _after_ the test has started, rather than when we're
#   imported at collection time.
import  sys

from    comci.util  import PROJECT_ROOT, debug, die, fprint

####################################################################

def command_run(args):
    ''' Run the testspecs (test names and parameters) given on the command
        line or, if none given, all the tests with their default parameters.
    '''
    die(9, 'XXX Write me!')
    for ts in tscripts(PROJECT_ROOT):
        #   XXX in both cases here we should be dealing with the optional
        #   single argument to the test(s) somehow?
        if args.interactive:
            run_ts_interactive(ts, arg=None)
        else:
            run_ts_capture(ts, arg=None, foreground=args.foreground)

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

def tscripts(project_root):
    for pts in sorted(project_root.glob('tscript/*')):
        is_exec = pts.stat().st_mode & S_IXUSR
        if not pts.is_file() or not is_exec: continue
        yield pts
