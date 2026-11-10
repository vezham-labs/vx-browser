package main

import (
	"debug/macho"
	"os"
	"path/filepath"
	"strings"
)

// This gate is intentionally specific to the current product bundle. It runs
// independently of signature checks and works for an unsigned Release build.
func nativeBundle(path string) []Check {
	resolved, err := filepath.EvalSymlinks(path)
	if err != nil {
		return []Check{{"bundle", "failed", "bundle unavailable"}}
	}
	resolved, err = filepath.Abs(resolved)
	if err != nil {
		return []Check{{"bundle", "failed", "invalid bundle path"}}
	}
	info := filepath.Join(resolved, "Contents", "Info.plist")
	var checks []Check
	add := func(name string, valid bool, reason string) {
		if valid {
			checks = append(checks, Check{name, "passed", ""})
		} else {
			checks = append(checks, Check{name, "failed", reason})
		}
	}
	for key, want := range map[string]string{
		"CFBundleExecutable": "VezhamBrowser", "CFBundleIdentifier": "internal.vezham.browser.foundation",
		"CFBundlePackageType": "APPL", "LSMinimumSystemVersion": "26.0",
	} {
		got, err := plist(info, key)
		add(key, err == nil && got == want, "missing or unexpected metadata")
	}
	for _, key := range []string{"CFBundleShortVersionString", "CFBundleVersion"} {
		got, err := plist(info, key)
		add(key, err == nil && got != "" && !strings.Contains(got, "$("), "missing or unresolved version")
	}
	executable := filepath.Join(resolved, "Contents", "MacOS", "VezhamBrowser")
	binary, err := filepath.EvalSymlinks(executable)
	if err != nil || !within(resolved, binary) {
		add("executable", false, "missing or escaped executable")
		return checks
	}
	st, err := os.Stat(binary)
	if err != nil || !st.Mode().IsRegular() || st.Mode()&0111 == 0 {
		add("executable", false, "executable unavailable")
		return checks
	}
	thin, err := macho.Open(binary)
	if err != nil {
		add("arm64", false, "expected a thin arm64 qualification candidate")
		return checks
	}
	defer thin.Close()
	add("arm64", thin.Cpu == macho.CpuArm64 && thin.Type == macho.TypeExec, "wrong executable architecture or type")
	libs, err := thin.ImportedLibraries()
	joined := strings.Join(libs, "\n")
	add("native-frameworks", err == nil && strings.Contains(joined, "/SwiftUI.framework/") &&
		strings.Contains(joined, "/AppKit.framework/") && strings.Contains(joined, "/WebKit.framework/"), "missing native frameworks")
	buildVersion := false
	for _, load := range thin.Loads {
		data := load.Raw()
		if len(data) >= 24 && thin.ByteOrder.Uint32(data) == 0x32 {
			buildVersion = thin.ByteOrder.Uint32(data[8:]) == 1 && thin.ByteOrder.Uint32(data[12:]) == 26<<16
		}
	}
	add("binary-minimum-os", buildVersion, "expected macOS 26.0 load command")
	add("development-runtime-libraries", err == nil && !strings.Contains(strings.ToLower(joined), "python.framework") &&
		!strings.Contains(joined, "/libpython") && !strings.Contains(joined, "/libgo."), "developer runtime linked")
	legacy := false
	err = filepath.WalkDir(filepath.Join(resolved, "Contents"), func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		name := strings.ToLower(entry.Name())
		switch filepath.Ext(name) {
		case ".html", ".css", ".js", ".mjs", ".jsx", ".py", ".go":
			legacy = true
		}
		if name == "chrome" {
			legacy = true
		}
		return nil
	})
	add("no-legacy-chrome-or-tool-sources", err == nil && !legacy, "legacy browser chrome or tool source in the bundle")
	return checks
}
