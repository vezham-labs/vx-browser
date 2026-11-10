package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func write(t *testing.T, path, content string) {
	t.Helper()
	if e := os.WriteFile(path, []byte(content), 0600); e != nil {
		t.Fatal(e)
	}
}
func TestEvidence(t *testing.T) {
	for _, scenario := range []string{"valid", "changed", "missing", "traversal", "absolute", "symlink", "duplicate", "invalid", "empty", "directory"} {
		t.Run(scenario, func(t *testing.T) {
			root := t.TempDir()
			outside := t.TempDir()
			write(t, filepath.Join(root, "data with spaces"), "record")
			name := "data with spaces"
			hash := fmt.Sprintf("%x", sha256.Sum256([]byte("record")))
			switch scenario {
			case "changed":
				hash = strings.Repeat("0", 64)
			case "missing":
				name = "absent"
			case "traversal":
				name = "../../escaped"
			case "absolute":
				name = filepath.Join(outside, "outside")
			case "symlink":
				write(t, filepath.Join(outside, "data"), "record")
				if e := os.Symlink(filepath.Join(outside, "data"), filepath.Join(root, "link")); e != nil {
					t.Fatal(e)
				}
				name = "link"
			case "directory":
				name = "."
			}
			manifest := hash + "  " + name + "\n"
			switch scenario {
			case "duplicate":
				manifest += manifest
			case "invalid":
				manifest = "not a checksum\n"
			case "empty":
				manifest = ""
			}
			m := filepath.Join(root, "SHA256SUMS")
			write(t, m, manifest)
			r := report("verify-evidence", evidence(root, m))
			if (r.Status == "passed") != (scenario == "valid") {
				t.Fatalf("%+v", r)
			}
		})
	}
}
func TestEvidenceRootAndMalformedDigest(t *testing.T) {
	root := t.TempDir()
	outside := t.TempDir()
	m := filepath.Join(outside, "SHA256SUMS")
	write(t, m, strings.Repeat("g", 64)+"  file\n")
	if report("verify", evidence(root, m)).Status != "failed" {
		t.Fatal("escaped manifest accepted")
	}
	if report("verify", evidence(outside, m)).Status != "failed" {
		t.Fatal("bad digest accepted")
	}
}
func TestAggregate(t *testing.T) {
	for _, tt := range []struct{ name, body, want string }{
		{"pass", `[{"id":"a","status":"passed"}]`, "passed"}, {"failure", `[{"id":"a","status":"failed"}]`, "failed"}, {"block", `[{"id":"a","status":"blocked"}]`, "blocked"}, {"notrun", `[{"id":"a","status":"not_executed"}]`, "blocked"}, {"skip", `[{"id":"a","status":"skipped"}]`, "blocked"}, {"na", `[{"id":"a","status":"not_applicable"}]`, "passed"}, {"unknown", `[{"id":"a","status":"PASS_NATIVE"}]`, "failed"}, {"duplicate", `[{"id":"a","status":"passed"},{"id":"a","status":"passed"}]`, "failed"}, {"emptyid", `[{"id":"","status":"passed"}]`, "failed"}, {"extra", `[{"id":"a","status":"passed","count":2}]`, "failed"}, {"trailing", `[{"id":"a","status":"passed"}] {}`, "failed"}, {"empty", `[]`, "failed"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			p := filepath.Join(t.TempDir(), "ledger.json")
			write(t, p, tt.body)
			if r := report("aggregate", aggregate(p)); r.Status != tt.want {
				t.Fatalf("%+v", r)
			}
		})
	}
}
func TestCLI(t *testing.T) {
	for _, args := range [][]string{nil, {"bogus"}, {"verify-evidence"}, {"aggregate-tests"}, {"release-preflight"}, {"verify-evidence", "--bogus"}, {"aggregate-tests", "extra"}} {
		var out bytes.Buffer
		if execute(args, &out) != 2 {
			t.Fatal(args, out.String())
		}
	}
	p := filepath.Join(t.TempDir(), "ledger.json")
	write(t, p, `[{"id":"a","status":"blocked"}]`)
	var first, second bytes.Buffer
	args := []string{"aggregate-tests", "--ledger", p}
	if execute(args, &first) != 3 || execute(args, &second) != 3 || first.String() != second.String() {
		t.Fatal("nondeterministic blocked result")
	}
}
func TestSubprocessCLI(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "vezham-qualify")
	if out, e := exec.Command("go", "build", "-o", binary, ".").CombinedOutput(); e != nil {
		t.Fatal(e, string(out))
	}
	root := t.TempDir()
	write(t, filepath.Join(root, "data"), "x")
	m := filepath.Join(root, "SHA256SUMS")
	write(t, m, fmt.Sprintf("%x  data\n", sha256.Sum256([]byte("x"))))
	if out, e := exec.Command(binary, "verify-evidence", "--root", root, "--manifest", m).CombinedOutput(); e != nil || !bytes.Contains(out, []byte(`"status": "passed"`)) {
		t.Fatal(e, string(out))
	}
	write(t, filepath.Join(root, "data"), "changed")
	out, e := exec.Command(binary, "verify-evidence", "--root", root, "--manifest", m).CombinedOutput()
	if exit, ok := e.(*exec.ExitError); !ok || exit.ExitCode() != 1 {
		t.Fatal(e, string(out))
	}
}
func TestPreflightMissingBundle(t *testing.T) {
	r := report("release", preflight(filepath.Join(t.TempDir(), "missing.app")))
	want := "failed"
	if runtime.GOOS != "darwin" {
		want = "blocked"
	}
	if r.Status != want {
		t.Fatal(r)
	}
}
func TestPlistDottedKeys(t *testing.T) {
	if runtime.GOOS != "darwin" {
		t.Skip("platform plist reader")
	}
	path := filepath.Join(t.TempDir(), "entitlements.plist")
	write(t, path, `<?xml version="1.0"?><plist version="1.0"><dict><key>com.apple.security.app-sandbox</key><true/></dict></plist>`)
	if v, e := plist(path, "com.apple.security.app-sandbox"); e != nil || v != "true" {
		t.Fatal(v, e)
	}
}

func TestAdHocBundleCannotPassRelease(t *testing.T) {
	if runtime.GOOS != "darwin" {
		t.Skip("macOS codesign required")
	}
	bundle := filepath.Join(t.TempDir(), "Fixture.app")
	contents := filepath.Join(bundle, "Contents")
	if e := os.MkdirAll(filepath.Join(contents, "MacOS"), 0700); e != nil {
		t.Fatal(e)
	}
	data, e := os.ReadFile("/usr/bin/true")
	if e != nil {
		t.Fatal(e)
	}
	if e = os.WriteFile(filepath.Join(contents, "MacOS", "Fixture"), data, 0700); e != nil {
		t.Fatal(e)
	}
	write(t, filepath.Join(contents, "Info.plist"), `<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>Fixture</string><key>CFBundleIdentifier</key><string>internal.vezham.qualify.fixture</string><key>CFBundleShortVersionString</key><string>1</string><key>CFBundleVersion</key><string>1</string><key>LSMinimumSystemVersion</key><string>26.0</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>`)
	ent := filepath.Join(t.TempDir(), "entitlements.plist")
	write(t, ent, `<?xml version="1.0"?><plist version="1.0"><dict><key>com.apple.security.app-sandbox</key><true/><key>com.apple.security.network.client</key><true/></dict></plist>`)
	if out, e := exec.Command("/usr/bin/codesign", "--force", "--sign", "-", "--options", "runtime", "--entitlements", ent, bundle).CombinedOutput(); e != nil {
		t.Fatal(e, string(out))
	}
	r := report("release-preflight", preflight(bundle))
	if r.Status != "blocked" {
		t.Fatalf("ad-hoc fixture release verdict: %+v", r)
	}
	found := map[string]string{}
	for _, c := range r.Checks {
		found[c.Name] = c.Status
	}
	for _, name := range []string{"signature-integrity", "hardened-runtime", "com.apple.security.app-sandbox", "com.apple.security.network.client"} {
		if found[name] != "passed" {
			t.Fatalf("%s: %+v", name, r)
		}
	}
	if found["developer-id"] != "blocked" || found["signed-runtime-qualification"] != "not_executed" {
		t.Fatalf("inflated release claim: %+v", r)
	}
}
