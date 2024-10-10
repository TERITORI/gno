package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"

	"github.com/gnolang/gno/gnovm/pkg/gnoenv"
	gno "github.com/gnolang/gno/gnovm/pkg/gnolang"
	"github.com/gnolang/gno/gnovm/pkg/importer"
	"github.com/gnolang/gno/gnovm/tests"
	"github.com/gnolang/gno/tm2/pkg/commands"
	"github.com/gnolang/gno/tm2/pkg/std"
)

type runCfg struct {
	verbose   bool
	rootDir   string
	expr      string
	debug     bool
	debugAddr string
}

func newRunCmd(io commands.IO) *commands.Command {
	cfg := &runCfg{}

	return commands.NewCommand(
		commands.Metadata{
			Name:       "run",
			ShortUsage: "run [flags] <file> [<file>...]",
			ShortHelp:  "runs the specified gno files",
		},
		cfg,
		func(_ context.Context, args []string) error {
			return execRun(cfg, args, io)
		},
	)
}

func (c *runCfg) RegisterFlags(fs *flag.FlagSet) {
	fs.BoolVar(
		&c.verbose,
		"v",
		false,
		"verbose output when running",
	)

	fs.StringVar(
		&c.rootDir,
		"root-dir",
		"",
		"clone location of github.com/gnolang/gno (gno binary tries to guess it)",
	)

	fs.StringVar(
		&c.expr,
		"expr",
		"main()",
		"value of expression to evaluate. Defaults to executing function main() with no args",
	)

	fs.BoolVar(
		&c.debug,
		"debug",
		false,
		"enable interactive debugger using stdin and stdout",
	)

	fs.StringVar(
		&c.debugAddr,
		"debug-addr",
		"",
		"enable interactive debugger using tcp address in the form [host]:port",
	)
}

func execRun(cfg *runCfg, args []string, io commands.IO) error {
	if len(args) == 0 {
		return flag.ErrHelp
	}

	if cfg.rootDir == "" {
		cfg.rootDir = gnoenv.RootDir()
	}

	stdin := io.In()
	stdout := io.Out()
	stderr := io.Err()

	// init store and machine
	testStore := tests.TestStore(cfg.rootDir,
		"", stdin, stdout, stderr,
		tests.ImportModeStdlibsPreferred)
	if cfg.verbose {
		testStore.SetLogStoreOps(true)
	}

	if len(args) == 0 {
		args = []string{"."}
	}

	// read files
	files, err := parseFiles(args, stderr)
	if err != nil {
		return err
	}

	if len(files) == 0 {
		return errors.New("no files to run")
	}

	var send std.Coins
	pkgPath := string(files[0].PkgName)
	ctx := tests.TestContext(pkgPath, send)
	m := gno.NewMachineWithOptions(gno.MachineOptions{
		PkgPath: pkgPath,
		Output:  stdout,
		Input:   stdin,
		Store:   testStore,
		Context: ctx,
		Debug:   cfg.debug || cfg.debugAddr != "",
	})

	defer m.Release()

	// If the debug address is set, the debugger waits for a remote client to connect to it.
	if cfg.debugAddr != "" {
		if err := m.Debugger.Serve(cfg.debugAddr); err != nil {
			return err
		}
	}

	// run files
	m.RunFiles(files...)
	runExpr(m, cfg.expr)

	return nil
}

func parseFiles(fnames []string, stderr io.WriteCloser) ([]*gno.FileNode, error) {
	gnoFnames, err := importer.Match(fnames, importer.MatchFiles("!*_test.gno", "!*_filetest.gno"))
	if err != nil {
		return nil, err
	}

	var hasError bool
	files := make([]*gno.FileNode, 0, len(gnoFnames))
	for _, fname := range gnoFnames {
		hasError = catchRuntimeError(fname, stderr, func() {
			files = append(files, gno.MustReadFile(fname))
		}) || hasError
	}
	if hasError {
		return nil, commands.ExitCodeError(1)
	}
	return files, nil
}

func runExpr(m *gno.Machine, expr string) {
	defer func() {
		if r := recover(); r != nil {
			switch r := r.(type) {
			case gno.UnhandledPanicError:
				fmt.Printf("panic running expression %s: %v\nStacktrace: %s\n",
					expr, r.Error(), m.ExceptionsStacktrace())
			default:
				fmt.Printf("panic running expression %s: %v\nMachine State:%s\nStacktrace: %s\n",
					expr, r, m.String(), m.Stacktrace().String())
			}
			panic(r)
		}
	}()
	ex, err := gno.ParseExpr(expr)
	if err != nil {
		panic(fmt.Errorf("could not parse: %w", err))
	}
	m.Eval(ex)
}
