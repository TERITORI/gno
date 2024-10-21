package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"go/scanner"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"

	"github.com/gnolang/gno/gnovm/pkg/gnoenv"
	"github.com/gnolang/gno/gnovm/pkg/gnomod"
	"github.com/gnolang/gno/gnovm/pkg/packages"
	"github.com/gnolang/gno/gnovm/pkg/transpiler"
	"github.com/gnolang/gno/tm2/pkg/commands"
)

type transpileCfg struct {
	verbose     bool
	rootDir     string
	skipImports bool
	gobuild     bool
	goBinary    string
	output      string
}

type transpileOptions struct {
	cfg *transpileCfg
	// CLI output
	io commands.IO
	// transpiled is the set of packages already
	// transpiled from .gno to .go.
	transpiled map[string]struct{}
	// skipped packages (gno mod marks them as draft)
	skipped []string
}

func newTranspileOptions(cfg *transpileCfg, io commands.IO) *transpileOptions {
	return &transpileOptions{
		cfg:        cfg,
		io:         io,
		transpiled: map[string]struct{}{},
	}
}

func (p *transpileOptions) getFlags() *transpileCfg {
	return p.cfg
}

func (p *transpileOptions) isTranspiled(pkg string) bool {
	_, transpiled := p.transpiled[pkg]
	return transpiled
}

func (p *transpileOptions) markAsTranspiled(pkg string) {
	p.transpiled[pkg] = struct{}{}
}

func newTranspileCmd(io commands.IO) *commands.Command {
	cfg := &transpileCfg{}

	return commands.NewCommand(
		commands.Metadata{
			Name:       "transpile",
			ShortUsage: "transpile [flags] <package> [<package>...]",
			ShortHelp:  "transpiles .gno files to .go",
		},
		cfg,
		func(_ context.Context, args []string) error {
			return execTranspile(cfg, args, io)
		},
	)
}

func (c *transpileCfg) RegisterFlags(fs *flag.FlagSet) {
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
		"clone location of github.com/gnolang/gno (gno tries to guess it)",
	)

	fs.BoolVar(
		&c.skipImports,
		"skip-imports",
		false,
		"do not transpile imports recursively",
	)

	fs.BoolVar(
		&c.gobuild,
		"gobuild",
		false,
		"run go build on generated go files, ignoring test files",
	)

	fs.StringVar(
		&c.goBinary,
		"go-binary",
		"go",
		"go binary to use for building",
	)

	fs.StringVar(
		&c.output,
		"output",
		".",
		"output directory",
	)
}

func execTranspile(cfg *transpileCfg, args []string, io commands.IO) error {
	if len(args) < 1 {
		return flag.ErrHelp
	}

	// guess cfg.RootDir
	if cfg.rootDir == "" {
		cfg.rootDir = gnoenv.RootDir()
	}

	// load packages
	pkgs, err := packages.Load(io, args...)
	if err != nil {
		return fmt.Errorf("load pkgs: %w", err)
	}
	pkgsMap := map[string]*packages.Package{}
	for _, pkg := range pkgs {
		pkgsMap[pkg.ImportPath] = pkg
	}

	// transpile .gno packages and files.
	opts := newTranspileOptions(cfg, io)
	var errlist scanner.ErrorList
	for _, pkg := range pkgs {
		// ignore deps
		if len(pkg.Match) == 0 {
			continue
		}

		st, err := os.Stat(pkg.Dir)
		if err != nil {
			return err
		}
		if st.IsDir() {
			err = transpilePkg(pkg, pkgsMap, opts)
		} else {
			panic("should ot try to transpile file yet")

			if opts.cfg.verbose {
				io.ErrPrintln(filepath.Clean(pkg.Dir))
			}

			err = transpileFile(pkg.Dir, pkgsMap, opts)
		}
		if err != nil {
			var fileErrlist scanner.ErrorList
			if !errors.As(err, &fileErrlist) {
				// Not an scanner.ErrorList: return immediately.
				return fmt.Errorf("%s: transpile: %w", pkg.ImportPath, err)
			}
			errlist = append(errlist, fileErrlist...)
		}
	}

	if errlist.Len() == 0 && cfg.gobuild {
		for _, pkg := range pkgs {
			if slices.Contains(opts.skipped, pkg.Dir) {
				continue
			}
			err := goBuildFileOrPkg(io, pkg.Dir, cfg)
			if err != nil {
				var fileErrlist scanner.ErrorList
				if !errors.As(err, &fileErrlist) {
					// Not an scanner.ErrorList: return immediately.
					return fmt.Errorf("%s: build: %w", pkg.ImportPath, err)
				}
				errlist = append(errlist, fileErrlist...)
			}
		}
	}

	if errlist.Len() > 0 {
		for _, err := range errlist {
			io.ErrPrintfln(err.Error())
		}
		return fmt.Errorf("%d transpile error(s)", errlist.Len())
	}
	return nil
}

// transpilePkg transpiles all non-test files at the given location.
// Additionally, it checks the gno.mod in said location, and skips it if it is
// a draft module
func transpilePkg(pkg *packages.Package, pkgs map[string]*packages.Package, opts *transpileOptions) error {
	dirPath := pkg.Dir
	if opts.isTranspiled(dirPath) {
		return nil
	}
	opts.markAsTranspiled(dirPath)

	gmod, err := gnomod.ParseAt(dirPath)
	if err != nil && !errors.Is(err, gnomod.ErrGnoModNotFound) {
		return err
	}
	if err == nil && gmod.Draft {
		if opts.cfg.verbose {
			opts.io.ErrPrintfln("%s (skipped, gno.mod marks module as draft)", filepath.Clean(dirPath))
		}
		opts.skipped = append(opts.skipped, dirPath)
		return nil
	}

	// XXX(morgan): Currently avoiding test files as they contain imports like "fmt".
	// The transpiler doesn't currently support "test stdlibs", and even if it
	// did all packages like "fmt" would have to exist as standard libraries to work.
	// Easier to skip for now.
	if opts.cfg.verbose {
		opts.io.ErrPrintln(filepath.Clean(dirPath))
	}
	for _, file := range pkg.GnoFiles {
		fpath := filepath.Join(pkg.Dir, file)
		if err := transpileFile(fpath, pkgs, opts); err != nil {
			return fmt.Errorf("%s: %w", file, err)
		}
	}

	return nil
}

func transpileFile(srcPath string, pkgs map[string]*packages.Package, opts *transpileOptions) error {
	flags := opts.getFlags()

	// parse .gno.
	source, err := os.ReadFile(srcPath)
	if err != nil {
		return fmt.Errorf("read: %w", err)
	}

	// compute attributes based on filename.
	targetFilename, tags := transpiler.TranspiledFilenameAndTags(srcPath)

	// preprocess.
	transpileRes, err := transpiler.Transpile(string(source), tags, srcPath)
	if err != nil {
		return fmt.Errorf("transpile: %w", err)
	}

	// resolve target path
	var targetPath string
	if flags.output != "." {
		path, err := ResolvePath(flags.output, filepath.Dir(srcPath))
		if err != nil {
			return fmt.Errorf("resolve output path: %w", err)
		}
		targetPath = filepath.Join(path, targetFilename)
	} else {
		targetPath = filepath.Join(filepath.Dir(srcPath), targetFilename)
	}

	// write .go file.
	err = WriteDirFile(targetPath, []byte(transpileRes.Translated))
	if err != nil {
		return fmt.Errorf("write .go file: %w", err)
	}

	// transpile imported packages, if `SkipImports` sets to false
	if !flags.skipImports &&
		!strings.HasSuffix(srcPath, "_filetest.gno") && !strings.HasSuffix(srcPath, "_test.gno") {
		for _, imp := range transpileRes.Imports {
			pkgPath, err := strconv.Unquote(imp.Path.Value)
			if err != nil {
				return fmt.Errorf("failed to unquote pkg path %v", imp.Path.Value)
			}
			pkgPath = strings.TrimPrefix(pkgPath, "github.com/gnolang/gno/gnovm/stdlibs/")
			pkgPath = strings.TrimPrefix(pkgPath, "github.com/gnolang/gno/examples/")
			dep := pkgs[pkgPath]
			if dep == nil {
				return fmt.Errorf("failed to find matching package for %q", pkgPath)
			}
			if err := transpilePkg(dep, pkgs, opts); err != nil {
				return err
			}
		}
	}

	return nil
}

func goBuildFileOrPkg(io commands.IO, fileOrPkg string, cfg *transpileCfg) error {
	verbose := cfg.verbose
	goBinary := cfg.goBinary

	if verbose {
		io.ErrPrintfln("%s [build]", filepath.Clean(fileOrPkg))
	}

	return buildTranspiledPackage(fileOrPkg, goBinary)
}

// buildTranspiledPackage tries to run `go build` against the transpiled .go files.
//
// This method is the most efficient to detect errors but requires that
// all the import are valid and available.
func buildTranspiledPackage(fileOrPkg, goBinary string) error {
	// TODO: use cmd/compile instead of exec?
	// TODO: find the nearest go.mod file, chdir in the same folder, trim prefix?
	// TODO: temporarily create an in-memory go.mod or disable go modules for gno?
	// TODO: ignore .go files that were not generated from gno?

	info, err := os.Stat(fileOrPkg)
	if err != nil {
		return fmt.Errorf("invalid file or package path %s: %w", fileOrPkg, err)
	}
	var (
		target string
		chdir  string
	)
	if !info.IsDir() {
		dstFilename, _ := transpiler.TranspiledFilenameAndTags(fileOrPkg)
		// Makes clear to go compiler that this is a relative path,
		// rather than a path to a package/module.
		// can't use filepath.Join as it cleans its results.
		target = filepath.Dir(fileOrPkg) + string(filepath.Separator) + dstFilename
	} else {
		// Go does not allow building packages using absolute paths, and requires
		// relative paths to always be prefixed with `./` (because the argument
		// go expects are import paths, not directories).
		// To circumvent this, we use the -C flag to chdir into the right
		// directory, then run `go build .`
		chdir = fileOrPkg
		target = "."
	}

	// pre-alloc max 5 args
	args := append(make([]string, 0, 5), "build")
	if chdir != "" {
		args = append(args, "-C", chdir)
	}
	args = append(args, "-tags=gno", target)
	cmd := exec.Command(goBinary, args...)
	out, err := cmd.CombinedOutput()
	if errors.As(err, new(*exec.ExitError)) {
		// there was a non-zero exit code; parse the go build errors
		return parseGoBuildErrors(string(out))
	}
	// other kinds of errors; return
	return err
}

var (
	reGoBuildError   = regexp.MustCompile(`(?m)^(\S+):(\d+):(\d+): (.+)$`)
	reGoBuildComment = regexp.MustCompile(`(?m)^#.*$`)
)

// parseGoBuildErrors returns a scanner.ErrorList filled with all errors found
// in out, which is supposed to be the output of the `go build` command.
//
// TODO(tb): update when `go build -json` is released to replace regexp usage.
// See https://github.com/golang/go/issues/62067
func parseGoBuildErrors(out string) error {
	var errList scanner.ErrorList
	matches := reGoBuildError.FindAllStringSubmatch(out, -1)
	for _, match := range matches {
		filename := match[1]
		line, err := strconv.Atoi(match[2])
		if err != nil {
			return fmt.Errorf("parse line go build error %s: %w", match, err)
		}

		column, err := strconv.Atoi(match[3])
		if err != nil {
			return fmt.Errorf("parse column go build error %s: %w", match, err)
		}
		msg := match[4]
		errList.Add(token.Position{
			Filename: filename,
			Line:     line,
			Column:   column,
		}, msg)
	}

	replaced := reGoBuildError.ReplaceAllLiteralString(out, "")
	replaced = reGoBuildComment.ReplaceAllString(replaced, "")
	replaced = strings.TrimSpace(replaced)
	if replaced != "" {
		errList.Add(token.Position{}, "Additional go build errors:\n"+replaced)
	}

	return errList.Err()
}
