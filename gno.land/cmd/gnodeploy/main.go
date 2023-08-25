package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	expect "github.com/Netflix/go-expect"
	"github.com/peterbourgon/ff/v3"
	"github.com/pkg/errors"
)

func main() {
	fs := flag.NewFlagSet("gnodeploy", flag.ContinueOnError)
	var (
		packagesRootFlag   = fs.String("root", "examples", "root directory of packages")
		targetsPkgPathFlag = fs.String("targets", "", "targets package paths")
		remoteGnowebFlag   = fs.String("remote-gnoweb", "https://testnet.gno.teritori.com", "remote gnoweb node")
		remoteGnoFlag      = fs.String("remote-gno", "testnet.gno.teritori.com:26657", "remote gno node")
		chainIdFlag        = fs.String("chain-id", "teritori-1", "remote chain id")
		walletNameFlag     = fs.String("wallet", "tester", "wallet name")
		depositFlag        = fs.String("deposit", "1ugnot", "deposit")
		gasFeeFlag         = fs.String("gas-fee", "1ugnot", "gas fee")
		gasWantedFlag      = fs.String("gas-wanted", "10000000", "gas wanted")
		passwordFlag       = fs.String("password", "", "password")
		ignoreFlag         = fs.String("ignore", "gno.land/p/demo/avl", "ignore packages")
	)

	err := ff.Parse(fs, os.Args[1:])
	if err != nil {
		panic(err)
	}

	if targetsPkgPathFlag == nil || *targetsPkgPathFlag == "" {
		panic("target package path is required")
	}
	targetsPkgPath := strings.Split(*targetsPkgPathFlag, ",")
	for i, targetPkgPath := range targetsPkgPath {
		targetsPkgPath[i] = strings.TrimSpace(targetPkgPath)
	}

	ignoreParts := strings.Split(*ignoreFlag, ",")
	ignores := map[string]struct{}{}
	for i, ignore := range ignoreParts {
		ignoreParts[i] = strings.TrimSpace(ignore)
		ignores[ignore] = struct{}{}
	}

	if packagesRootFlag == nil || *packagesRootFlag == "" {
		panic("packages root is required")
	}
	packagesRoot := *packagesRootFlag

	if remoteGnowebFlag == nil || *remoteGnowebFlag == "" {
		panic("remote gnoweb node is required")
	}
	remoteGnoweb := *remoteGnowebFlag

	if remoteGnoFlag == nil || *remoteGnoFlag == "" {
		panic("remote gno node is required")
	}
	remoteGno := *remoteGnoFlag

	if chainIdFlag == nil || *chainIdFlag == "" {
		panic("chain id is required")
	}
	chainId := *chainIdFlag

	if walletNameFlag == nil || *walletNameFlag == "" {
		panic("wallet name is required")
	}
	walletName := *walletNameFlag

	if depositFlag == nil || *depositFlag == "" {
		panic("deposit is required")
	}
	deposit := *depositFlag

	if gasFeeFlag == nil || *gasFeeFlag == "" {
		panic("gas fee is required")
	}
	gasFee := *gasFeeFlag

	if gasWantedFlag == nil || *gasWantedFlag == "" {
		panic("gas wanted is required")
	}
	gasWanted := *gasWantedFlag

	// empty password is ok
	password := *passwordFlag

	fmt.Print("Target packages:\n\n")
	for _, targetPkgPath := range targetsPkgPath {
		fmt.Println(targetPkgPath)
	}

	allGnoMods := map[string]struct{}{}
	if err := filepath.Walk(packagesRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Println("error during walk:", err)
			return nil
		}
		if info.IsDir() || info.Name() != "gno.mod" {
			return nil
		}

		allGnoMods[path] = struct{}{}

		return nil
	}); err != nil {
		panic(errors.Wrap(err, "failed to walk packages"))
	}

	for _, targetPkgPath := range targetsPkgPath {
		if _, ok := ignores[targetPkgPath]; ok {
			panic("target package " + targetPkgPath + " is ignored")
		}
		targetPackageFSPath := filepath.Join(packagesRoot, targetPkgPath)
		targetPackageGnoModPath := filepath.Join(targetPackageFSPath, "gno.mod")
		if _, ok := allGnoMods[targetPackageGnoModPath]; !ok {
			panic("target package " + targetPkgPath + " not found")
		}
	}

	requires := map[string][]string{}
	requiredBy := map[string][]string{}
	for gnoModPath := range allGnoMods {
		deps, err := gnoModDeps(gnoModPath)
		if err != nil {
			panic(errors.Wrap(err, "failed to parse "+gnoModPath))
		}

		pkgPath := strings.TrimSuffix(strings.TrimPrefix(gnoModPath, packagesRoot+"/"), "/gno.mod") // FIXME: brittle, not cross-platform

		requires[pkgPath] = deps
		for _, dep := range deps {
			requiredBy[dep] = append(requiredBy[dep], pkgPath)
		}
	}

	upgrades := map[string]string{}

	fmt.Println("\nFetching versions from remote...")

	// recursively get deps of targets
	seen := map[string]struct{}{}
	roots := targetsPkgPath
	targetsAndDeps := map[string]struct{}{}
	for len(roots) > 0 {
		pkgPath := roots[0]
		roots = roots[1:]
		if _, ok := seen[pkgPath]; ok {
			continue
		}
		seen[pkgPath] = struct{}{}
		if _, ok := ignores[pkgPath]; ok {
			continue
		}
		roots = append(roots, requires[pkgPath]...)
		targetsAndDeps[pkgPath] = struct{}{}
	}

	roots = []string{}
	for pkgPath := range targetsAndDeps {
		roots = append(roots, pkgPath)
	}

	// find versions and upgrades
	seen = map[string]struct{}{}
	for len(roots) > 0 {
		pkgPath := roots[0]
		roots = roots[1:]
		if _, ok := seen[pkgPath]; ok {
			continue
		}
		seen[pkgPath] = struct{}{}
		if _, ok := ignores[pkgPath]; ok {
			continue
		}
		roots = append(roots, requiredBy[pkgPath]...)

		// find highest version on remote
		nextVersion := 2
		for {
			resp, err := http.Get(fmt.Sprintf("%s/%s_v%d/", remoteGnoweb, strings.TrimPrefix(pkgPath, "gno.land/"), nextVersion)) // last slash is important so we query sources and don't run into problems with render errors in realms
			if err != nil {
				panic(errors.Wrap(err, "failed to get "+pkgPath))
			}
			if resp.StatusCode == 500 {
				break
			}
			if resp.StatusCode != 200 {
				panic("unexpected status code: " + strconv.Itoa(resp.StatusCode))
			}
			nextVersion++
		}

		newPkgPath := fmt.Sprintf("%s_v%d", pkgPath, nextVersion)
		upgrades[pkgPath] = newPkgPath
	}

	fmt.Println("\nWill upgrade", len(upgrades), "packages")

	fmt.Println("\nCopying root to temporary directory...")
	tmpDir := ".deploy"
	if err := os.RemoveAll(tmpDir); err != nil {
		panic(errors.Wrap(err, "failed to remove "+tmpDir))
	}
	cmd := exec.Command("cp", "-r", packagesRoot, tmpDir)
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		panic(errors.Wrap(err, "failed to copy "+packagesRoot))
	}

	// preversedPackagesRoot := packagesRoot
	packagesRoot = tmpDir

	fmt.Print("\nBumping:\n\n")

	for oldPkgPath, newPkgPath := range upgrades {
		fmt.Println(oldPkgPath, "->", newPkgPath)

		r := regexp.MustCompile(oldPkgPath)

		// change module name in gno.mod
		gnoModPath := filepath.Join(packagesRoot, oldPkgPath, "gno.mod")
		data, err := os.ReadFile(gnoModPath)
		if err != nil {
			panic(errors.Wrap(err, "failed to read "+gnoModPath))
		}
		edited := r.ReplaceAll(data, []byte(newPkgPath))
		if err := os.WriteFile(gnoModPath, edited, 0644); err != nil {
			panic(errors.Wrap(err, "failed to write "+gnoModPath))
		}

		for _, child := range requiredBy[oldPkgPath] {
			// change import paths in dependent .gno files
			if err := filepath.Walk(filepath.Join(packagesRoot, child), func(path string, info os.FileInfo, err error) error {
				if err != nil {
					fmt.Println("error during walk:", err)
					return nil
				}

				if info.IsDir() || !strings.HasSuffix(path, ".gno") {
					return nil
				}

				// replace oldPkgPath with newPkgPath in file
				data, err := os.ReadFile(path)
				if err != nil {
					return errors.Wrap(err, "failed to read "+path)
				}
				edited := r.ReplaceAll(data, []byte(newPkgPath))
				if err := os.WriteFile(path, edited, 0644); err != nil {
					return errors.Wrap(err, "failed to write "+path)
				}

				return nil
			}); err != nil {
				panic(errors.Wrap(err, "failed to walk packages"))
			}

			// change import paths in dependent gno.mod files
			gnoModPath := filepath.Join(packagesRoot, child, "gno.mod")
			data, err := os.ReadFile(gnoModPath)
			if err != nil {
				panic(errors.Wrap(err, "failed to read "+gnoModPath))
			}
			edited := r.ReplaceAll(data, []byte(newPkgPath))
			if err := os.WriteFile(gnoModPath, edited, 0644); err != nil {
				panic(errors.Wrap(err, "failed to write "+gnoModPath))
			}
		}
	}

	for oldPkgPath, newPkgPath := range upgrades {
		// rename directory
		if err := os.Rename(filepath.Join(packagesRoot, oldPkgPath), filepath.Join(packagesRoot, newPkgPath)); err != nil {
			panic(errors.Wrap(err, "failed to rename "+oldPkgPath))
		}
	}

	fmt.Print("\nDeploying:\n\n")

	// deploy packages in dependency order
	deployed := map[string]struct{}{}
	remaining := map[string]struct{}{}
	for pkgPath := range upgrades {
		remaining[pkgPath] = struct{}{}
	}
	for len(remaining) > 0 {
		leafs := map[string]struct{}{}
		for pkgPath := range remaining {
			deps := requires[pkgPath]
			if len(deps) == 0 {
				leafs[pkgPath] = struct{}{}
			}
			hasDep := false
			for _, dep := range deps {
				if _, ok := upgrades[dep]; ok {
					if _, ok := deployed[dep]; !ok {
						hasDep = true
						break
					}
				}
			}
			if !hasDep {
				leafs[pkgPath] = struct{}{}
			}
		}

		if len(leafs) == 0 {
			panic("no leafs found, probably a cylic dependency")
		}

		for leaf := range leafs {
			fmt.Println(upgrades[leaf])
			c, err := expect.NewConsole()
			if err != nil {
				panic(errors.Wrap(err, "failed to create console"))
			}
			cmd := exec.Command("gnokey", "maketx", "addpkg",
				"-deposit="+deposit,
				"-gas-fee="+gasFee,
				"-gas-wanted="+gasWanted,
				"-broadcast=true",
				"-remote="+remoteGno,
				"-chainid="+chainId,
				"-pkgdir="+filepath.Join(packagesRoot, upgrades[leaf]),
				"-pkgpath="+upgrades[leaf],
				walletName,
			)

			buf := bytes.NewBuffer(nil)
			multiWriter := io.MultiWriter(c.Tty(), buf)
			cmd.Stderr = multiWriter
			cmd.Stdout = multiWriter
			cmd.Stdin = c.Tty()

			go func() {
				c.ExpectString("Enter password.")
				c.SendLine(password)
			}()

			if err := cmd.Run(); err != nil {
				fmt.Println("\n" + buf.String())
				panic(errors.Wrap(err, "failed to deploy "+upgrades[leaf]))
			}

			deployed[leaf] = struct{}{}
			delete(remaining, leaf)
		}
	}
}

func gnoModDeps(gnoModPath string) ([]string, error) {
	data, err := os.ReadFile(gnoModPath)
	if err != nil {
		return nil, errors.Wrap(err, "failed to read "+gnoModPath)
	}
	r := regexp.MustCompile(`(?s)require.+?\((.+?)\)`)
	submatches := r.FindAllStringSubmatch(string(data), -1)
	if len(submatches) < 1 || len(submatches[0]) < 2 {
		return nil, nil
	}
	lines := strings.Split(submatches[0][1], "\n")
	depEntries := []string{}
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		depR := regexp.MustCompile(`"(.+)"`)
		submatches := depR.FindAllStringSubmatch(line, -1)
		if len(submatches) < 1 || len(submatches[0]) < 2 {
			return nil, fmt.Errorf("failed to parse dep line: %q", line)
		}
		depEntry := submatches[0][1]
		depEntries = append(depEntries, depEntry)
	}
	return depEntries, nil
}
