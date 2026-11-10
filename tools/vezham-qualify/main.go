// vezham-qualify is development tooling. It is never linked into the application.
package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"time"
)

type Check struct {
	Name   string `json:"name"`
	Status string `json:"status"`
	Reason string `json:"reason,omitempty"`
}
type Report struct {
	Command string  `json:"command"`
	Status  string  `json:"status"`
	Checks  []Check `json:"checks"`
}

func report(command string, checks []Check) Report {
	sort.SliceStable(checks, func(i, j int) bool { return checks[i].Name < checks[j].Name })
	status := "passed"
	if len(checks) == 0 {
		status = "failed"
	}
	for _, c := range checks {
		if (c.Status == "blocked" || c.Status == "not_executed" || c.Status == "skipped") && status == "passed" {
			status = "blocked"
		}
		if c.Status == "failed" {
			status = "failed"
		}
	}
	return Report{command, status, checks}
}
func within(root, path string) bool {
	r, e := filepath.Rel(root, path)
	return e == nil && r != ".." && !strings.HasPrefix(r, ".."+string(filepath.Separator)) && !filepath.IsAbs(r)
}

// Manifest entries are relative to their manifest, matching historical sha256sum semantics.
// A caller-supplied root bounds symlinks and parent references without rewriting evidence.
func evidence(root, manifest string) []Check {
	root, e := filepath.EvalSymlinks(root)
	if e != nil {
		return []Check{{manifest, "failed", "invalid root"}}
	}
	root, e = filepath.Abs(root)
	if e != nil {
		return []Check{{manifest, "failed", "invalid root"}}
	}
	real, e := filepath.EvalSymlinks(manifest)
	if e != nil {
		return []Check{{manifest, "failed", "manifest unavailable"}}
	}
	real, e = filepath.Abs(real)
	if e != nil || !within(root, real) {
		return []Check{{manifest, "failed", "manifest outside root"}}
	}
	if info, err := os.Stat(real); err != nil || !info.Mode().IsRegular() {
		return []Check{{manifest, "failed", "manifest must be a regular file"}}
	}
	f, e := os.Open(real)
	if e != nil {
		return []Check{{manifest, "failed", "manifest unavailable"}}
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	s.Buffer(make([]byte, 4096), 1024*1024)
	checks := []Check{}
	seen := map[string]bool{}
	line := 0
	for s.Scan() {
		line++
		raw := s.Text()
		if raw == "" {
			continue
		}
		name := fmt.Sprintf("line:%d", line)
		if len(raw) < 67 || raw[64] != ' ' || (raw[65] != ' ' && raw[65] != '*') {
			checks = append(checks, Check{name, "failed", "invalid checksum entry"})
			continue
		}
		digest, err := hex.DecodeString(raw[:64])
		if err != nil || len(digest) != 32 {
			checks = append(checks, Check{name, "failed", "invalid SHA256"})
			continue
		}
		name = raw[66:]
		if name == "" || strings.ContainsAny(name, "\x00\r\n") || filepath.IsAbs(name) {
			checks = append(checks, Check{name, "failed", "invalid relative path"})
			continue
		}
		path := filepath.Clean(filepath.Join(filepath.Dir(real), name))
		if seen[path] {
			checks = append(checks, Check{name, "failed", "duplicate entry"})
			continue
		}
		seen[path] = true
		if !within(root, path) {
			checks = append(checks, Check{name, "failed", "path outside root"})
			continue
		}
		resolved, err := filepath.EvalSymlinks(path)
		if err != nil {
			checks = append(checks, Check{name, "failed", "missing evidence"})
			continue
		}
		if !within(root, resolved) {
			checks = append(checks, Check{name, "failed", "symlink outside root"})
			continue
		}
		if info, err := os.Stat(resolved); err != nil || !info.Mode().IsRegular() {
			checks = append(checks, Check{name, "failed", "not a regular file"})
			continue
		}
		file, err := os.Open(resolved)
		if err != nil {
			checks = append(checks, Check{name, "failed", "unreadable evidence"})
			continue
		}
		info, err := file.Stat()
		if err != nil || !info.Mode().IsRegular() {
			file.Close()
			checks = append(checks, Check{name, "failed", "not a regular file"})
			continue
		}
		h := sha256.New()
		_, err = io.Copy(h, file)
		closeErr := file.Close()
		if err != nil || closeErr != nil {
			checks = append(checks, Check{name, "failed", "evidence read failed"})
			continue
		}
		if !strings.EqualFold(hex.EncodeToString(h.Sum(nil)), raw[:64]) {
			checks = append(checks, Check{name, "failed", "checksum mismatch"})
		} else {
			checks = append(checks, Check{name, "passed", ""})
		}
	}
	if s.Err() != nil {
		checks = append(checks, Check{"manifest", "failed", "manifest read failed"})
	}
	if line == 0 || len(checks) == 0 {
		checks = append(checks, Check{"manifest", "failed", "empty manifest"})
	}
	return checks
}

type Case struct {
	ID     string `json:"id"`
	Status string `json:"status"`
}

// A deliberately explicit interchange format. Existing suites must be converted
// from their actual result records, never inferred from prose or an exit code.
func aggregate(path string) []Check {
	b, e := os.ReadFile(path)
	if e != nil {
		return []Check{{"ledger", "failed", "unreadable ledger"}}
	}
	var rows []Case
	d := json.NewDecoder(strings.NewReader(string(b)))
	d.DisallowUnknownFields()
	if d.Decode(&rows) != nil || len(rows) == 0 {
		return []Check{{"ledger", "failed", "expected nonempty array of id/status records"}}
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return []Check{{"ledger", "failed", "trailing JSON"}}
	}
	checks := []Check{}
	seen := map[string]bool{}
	for _, row := range rows {
		status := row.Status
		switch status {
		case "passed", "failed", "blocked", "skipped", "not_executed", "not_applicable":
		default:
			status = "failed"
		}
		reason := ""
		if strings.TrimSpace(row.ID) == "" || seen[row.ID] {
			status = "failed"
			reason = "missing or duplicate case ID"
		}
		if status != row.Status && reason == "" {
			reason = "unknown result classification"
		}
		seen[row.ID] = true
		checks = append(checks, Check{row.ID, status, reason})
	}
	return checks
}

func run(name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	b, e := exec.CommandContext(ctx, name, args...).CombinedOutput()
	return string(b), e
}
func plist(path, key string) (string, error) {
	raw, err := run("/usr/bin/plutil", "-convert", "json", "-o", "-", path)
	if err != nil {
		return "", err
	}
	var values map[string]any
	if err = json.Unmarshal([]byte(raw), &values); err != nil {
		return "", err
	}
	value, ok := values[key]
	if !ok {
		return "", fmt.Errorf("missing key")
	}
	return fmt.Sprint(value), nil
}
func hasHardenedRuntime(signature string) bool {
	for _, line := range strings.Split(signature, "\n") {
		if !strings.HasPrefix(line, "CodeDirectory ") {
			continue
		}
		_, flags, found := strings.Cut(line, " flags=")
		if !found {
			continue
		}
		_, values, found := strings.Cut(flags, "(")
		if !found {
			continue
		}
		values, _, found = strings.Cut(values, ")")
		if !found {
			continue
		}
		for _, flag := range strings.Split(values, ",") {
			if strings.TrimSpace(flag) == "runtime" {
				return true
			}
		}
	}
	return false
}

func preflight(bundle string) []Check {
	if runtime.GOOS != "darwin" {
		return []Check{{"platform", "blocked", "macOS tools required"}}
	}
	bundle, e := filepath.Abs(bundle)
	if e != nil {
		return []Check{{"bundle", "failed", "invalid bundle path"}}
	}
	info := filepath.Join(bundle, "Contents", "Info.plist")
	checks := []Check{}
	values := map[string]string{}
	for _, key := range []string{"CFBundleExecutable", "CFBundleIdentifier", "CFBundleShortVersionString", "CFBundleVersion", "LSMinimumSystemVersion", "CFBundlePackageType"} {
		value, err := plist(info, key)
		value = strings.TrimSpace(value)
		status := "passed"
		reason := ""
		if err != nil || value == "" || strings.Contains(value, "$(") {
			status = "failed"
			reason = "missing or unresolved metadata"
		}
		values[key] = value
		checks = append(checks, Check{key, status, reason})
	}
	if values["CFBundlePackageType"] != "APPL" {
		checks = append(checks, Check{"bundle-type", "failed", "expected APPL"})
	}
	exe := values["CFBundleExecutable"]
	if exe == "" || filepath.Base(exe) != exe || exe == "." || exe == ".." {
		checks = append(checks, Check{"executable", "failed", "invalid executable name"})
		return checks
	}
	binary := filepath.Join(bundle, "Contents", "MacOS", exe)
	if st, err := os.Stat(binary); err != nil || !st.Mode().IsRegular() || st.Mode()&0111 == 0 {
		checks = append(checks, Check{"executable", "failed", "executable unavailable"})
		return checks
	}
	if _, err := run("/usr/bin/codesign", "--verify", "--deep", "--strict", bundle); err != nil {
		checks = append(checks, Check{"signature-integrity", "failed", "codesign verification failed"})
	} else {
		checks = append(checks, Check{"signature-integrity", "passed", "includes nested code verification"})
	}
	signature, err := run("/usr/bin/codesign", "-d", "--verbose=4", bundle)
	if err != nil {
		checks = append(checks, Check{"developer-id", "blocked", "no inspectable signature"})
	} else {
		status := "passed"
		reason := ""
		if strings.Contains(signature, "Signature=adhoc") || !strings.Contains(signature, "Authority=Developer ID Application:") || !strings.Contains(signature, "TeamIdentifier=") {
			status = "blocked"
			reason = "Developer ID Application signature required"
		}
		checks = append(checks, Check{"developer-id", status, reason})
		status = "failed"
		if hasHardenedRuntime(signature) {
			status = "passed"
		}
		checks = append(checks, Check{"hardened-runtime", status, ""})
	}
	entitlements, err := run("/usr/bin/codesign", "-d", "--entitlements", ":-", bundle)
	if err != nil {
		checks = append(checks, Check{"entitlements", "failed", "cannot inspect signed entitlements"})
	} else {
		// Parse via the platform plist reader rather than substring-matching XML.
		f, err := os.CreateTemp("", "vezham-entitlements-*.plist")
		if err != nil {
			checks = append(checks, Check{"entitlements", "failed", "temporary file unavailable"})
		} else {
			defer os.Remove(f.Name())
			start := strings.Index(entitlements, "<?xml")
			end := strings.Index(entitlements, "</plist>")
			if start < 0 || end < start {
				checks = append(checks, Check{"entitlements", "failed", "no XML entitlement payload"})
				f.Close()
			} else {
				_, writeErr := f.WriteString(entitlements[start : end+len("</plist>")])
				closeErr := f.Close()
				if writeErr != nil || closeErr != nil {
					checks = append(checks, Check{"entitlements", "failed", "cannot inspect payload"})
				} else {
					for _, key := range []string{"com.apple.security.app-sandbox", "com.apple.security.network.client"} {
						v, err := plist(f.Name(), key)
						status := "passed"
						if err != nil || strings.TrimSpace(v) != "true" {
							status = "failed"
						}
						checks = append(checks, Check{key, status, ""})
					}
					for _, key := range []string{"com.apple.security.get-task-allow", "com.apple.security.cs.disable-library-validation", "com.apple.security.cs.allow-unsigned-executable-memory"} {
						v, err := plist(f.Name(), key)
						status := "passed"
						if err == nil && strings.TrimSpace(v) != "false" {
							status = "failed"
						}
						checks = append(checks, Check{key, status, ""})
					}
				}
			}
		}
	}
	// Signature validity alone does not prove notarization, install behavior, or runtime qualification.
	checks = append(checks, Check{"signed-runtime-qualification", "not_executed", "requires a separate real signed application run"})
	if _, err := run("/usr/bin/xcrun", "stapler", "validate", bundle); err != nil {
		checks = append(checks, Check{"notarization-ticket", "blocked", "valid stapled ticket unavailable"})
	} else {
		checks = append(checks, Check{"notarization-ticket", "passed", "ticket validation only"})
	}
	return checks
}

func execute(args []string, out io.Writer) int {
	if len(args) == 0 {
		fmt.Fprintln(out, "usage: vezham-qualify verify-evidence --root DIR --manifest FILE | aggregate-tests --ledger FILE | release-preflight --bundle APP | native-bundle --bundle APP | production-preflight --bundle APP | verify-workspace-matrix --root DIR --manifest FILE --matrix FILE")
		return 2
	}
	flags := flag.NewFlagSet(args[0], flag.ContinueOnError)
	flags.SetOutput(out)
	root := flags.String("root", ".", "allowed evidence root")
	manifest := flags.String("manifest", "", "SHA256SUMS path")
	ledger := flags.String("ledger", "", "JSON array of id/status records")
	matrix := flags.String("matrix", "", "WS-F7 case records")
	bundle := flags.String("bundle", "", "application bundle")
	if flags.Parse(args[1:]) != nil || flags.NArg() != 0 {
		return 2
	}
	var checks []Check
	switch args[0] {
	case "verify-evidence":
		if *manifest == "" {
			fmt.Fprintln(out, "--manifest required")
			return 2
		}
		checks = evidence(*root, *manifest)
	case "aggregate-tests":
		if *ledger == "" {
			fmt.Fprintln(out, "--ledger required")
			return 2
		}
		checks = aggregate(*ledger)
	case "verify-workspace-matrix":
		if *manifest == "" || *matrix == "" {
			fmt.Fprintln(out, "--manifest and --matrix required")
			return 2
		}
		checks = verifyWorkspaceMatrix(*root, *manifest, *matrix)
	case "production-preflight":
		if *bundle == "" {
			fmt.Fprintln(out, "--bundle required")
			return 2
		}
		checks = append(nativeBundle(*bundle), preflight(*bundle)...)
	case "native-bundle":
		if *bundle == "" {
			fmt.Fprintln(out, "--bundle required")
			return 2
		}
		checks = nativeBundle(*bundle)
	case "release-preflight":
		if *bundle == "" {
			fmt.Fprintln(out, "--bundle required")
			return 2
		}
		checks = preflight(*bundle)
	default:
		fmt.Fprintln(out, "unknown command")
		return 2
	}
	r := report(args[0], checks)
	// An aggregate with unexecuted/blocked/skipped cases is never an all-passed suite.
	if args[0] == "aggregate-tests" && r.Status == "passed" {
		for _, c := range checks {
			if c.Status == "skipped" || c.Status == "not_executed" {
				r.Status = "blocked"
			}
		}
	}
	e := json.NewEncoder(out)
	e.SetIndent("", "  ")
	if e.Encode(r) != nil {
		return 1
	}
	if r.Status == "failed" {
		return 1
	}
	if r.Status == "blocked" {
		return 3
	}
	return 0
}
func main() { os.Exit(execute(os.Args[1:], os.Stdout)) }
