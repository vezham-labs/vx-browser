//go:build protectedstore && darwin

package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

const testProfile = "10000000-0000-4000-8000-000000000001"
const testStore = "20000000-0000-4000-8000-000000000001"

type workerResult struct {
	status, revision uint64
	payload          []byte
	exit             int
}

func compileWorker(t *testing.T) string {
	t.Helper()
	provider := os.Getenv("VEZHAM_SQLCIPHER_PROVIDER")
	if provider == "" {
		t.Fatal("VEZHAM_SQLCIPHER_PROVIDER must name verified retained provider artifacts")
	}
	for name, want := range map[string]string{"libsqlite3.a": "ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c", "sqlite3.h": "e36eb6ed4de77e56a633866a8f84ed339785662d0cf79cf099f420b638bf28ec"} {
		data, e := os.ReadFile(filepath.Join(provider, name))
		if e != nil || fmt.Sprintf("%x", sha256.Sum256(data)) != want {
			t.Fatal("pinned provider verification failed:", name)
		}
	}
	source := filepath.Join("..", "..", "apps", "browser-macos", "ProtectedStoreWorker")
	out := filepath.Join(t.TempDir(), "workspace-store")
	cmd := exec.Command("xcrun", "clang", "-std=c17", "-Wall", "-Wextra", "-Werror", "-DSQLITE_HAS_CODEC", "-DVEZHAM_STORE_TESTING", "-I", provider, filepath.Join(source, "descriptor_vfs.c"), filepath.Join(source, "workspace_store.c"), filepath.Join(provider, "libsqlite3.a"), "-framework", "Security", "-framework", "CoreFoundation", "-o", out)
	if data, e := cmd.CombinedOutput(); e != nil {
		t.Fatalf("worker compile: %v\n%s", e, data)
	}
	return out
}
func requestWorker(t *testing.T, binaryPath, root, mode, profile, store string, key []byte, expected uint64, payload []byte, fail string) workerResult {
	t.Helper()
	var input bytes.Buffer
	input.Write(key)
	if mode == "save" || mode == "create" {
		binary.Write(&input, binary.LittleEndian, uint32(len(payload)))
		input.Write(payload)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binaryPath, mode, root, profile, store, fmt.Sprint(expected), fail)
	cmd.Stdin = &input
	var output bytes.Buffer
	cmd.Stdout = &output
	var diagnostic bytes.Buffer
	cmd.Stderr = &diagnostic
	e := cmd.Run()
	if e != nil {
		if exit, ok := e.(*exec.ExitError); ok && (exit.ExitCode() == 86 || exit.ExitCode() == 87) {
			return workerResult{exit: exit.ExitCode()}
		}
		t.Fatal("worker process failed (no payload diagnostic)", e)
	}
	raw := output.Bytes()
	if len(raw) < 24 {
		t.Fatal("truncated worker result")
	}
	status := binary.LittleEndian.Uint64(raw)
	rev := binary.LittleEndian.Uint64(raw[8:])
	n := binary.LittleEndian.Uint64(raw[16:])
	if n > 256*1024 || uint64(len(raw)-24) != n {
		t.Fatal("invalid IPC frame")
	}
	// No plaintext marker may be sent to the diagnostics stream.
	if bytes.Contains(diagnostic.Bytes(), []byte("SYNTHETIC-WORKSPACE")) {
		t.Fatal("payload leaked to diagnostics")
	}
	return workerResult{status: status, revision: rev, payload: append([]byte(nil), raw[24:]...)}
}
func TestProtectedStore(t *testing.T) {
	worker := compileWorker(t)
	key := make([]byte, 32)
	if _, e := rand.Read(key); e != nil {
		t.Fatal(e)
	}
	initial := []byte("SYNTHETIC-WORKSPACE revision zero")
	updated := []byte("SYNTHETIC-WORKSPACE revision one")
	setup := func(t *testing.T) string {
		t.Helper()
		root := t.TempDir()
		if e := os.Chmod(root, 0700); e != nil {
			t.Fatal(e)
		}
		r := requestWorker(t, worker, root, "create", testProfile, testStore, key, 0, initial, "")
		if r.status != 0 || r.revision != 0 {
			t.Fatal("creation", r.status)
		}
		return root
	}
	call := func(t *testing.T, root, mode string, expected uint64, payload []byte, fail string) workerResult {
		return requestWorker(t, worker, root, mode, testProfile, testStore, key, expected, payload, fail)
	}
	hash := func(t *testing.T, root string) [32]byte {
		data, e := os.ReadFile(filepath.Join(root, "catalog.vws"))
		if e != nil {
			t.Fatal(e)
		}
		return sha256.Sum256(data)
	}
	t.Run("encrypted-reopen-and-CAS", func(t *testing.T) {
		root := setup(t)
		r := call(t, root, "load", 0, nil, "")
		if r.status != 0 || !bytes.Equal(r.payload, initial) {
			t.Fatal("restore")
		}
		r = call(t, root, "save", 0, updated, "")
		if r.status != 0 || r.revision != 1 {
			t.Fatal("commit", r.status)
		}
		r = call(t, root, "load", 0, nil, "")
		if r.status != 0 || r.revision != 1 || !bytes.Equal(r.payload, updated) {
			t.Fatal("reopen")
		}
		data, _ := os.ReadFile(filepath.Join(root, "catalog.vws"))
		if bytes.Contains(data, initial) || bytes.Contains(data, updated) || bytes.HasPrefix(data, []byte("SQLite format 3")) {
			t.Fatal("unencrypted payload")
		}
		before := hash(t, root)
		r = call(t, root, "save", 0, initial, "")
		if r.status != 3 || hash(t, root) != before {
			t.Fatal("stale revision modified source")
		}
	})
	t.Run("wrong-key-and-owner-preserve-source", func(t *testing.T) {
		root := setup(t)
		before := hash(t, root)
		wrong := append([]byte(nil), key...)
		wrong[0] ^= 0xff
		r := requestWorker(t, worker, root, "load", testProfile, testStore, wrong, 0, nil, "")
		if r.status != 2 || hash(t, root) != before {
			t.Fatal("wrong key")
		}
		r = requestWorker(t, worker, root, "load", "30000000-0000-4000-8000-000000000001", testStore, key, 0, nil, "")
		if r.status != 1 || hash(t, root) != before {
			t.Fatal("foreign owner")
		}
	})
	t.Run("missing-key-no-files", func(t *testing.T) {
		root := t.TempDir()
		os.Chmod(root, 0700)
		r := requestWorker(t, worker, root, "create", testProfile, testStore, make([]byte, 32), 0, initial, "")
		entries, _ := os.ReadDir(root)
		if r.status != 1 || len(entries) != 0 {
			t.Fatal("missing key admitted")
		}
	})
	for _, mode := range []string{"fail-before-publish", "crash-before-publish", "crash-after-publish", "unknown-after-publish"} {
		t.Run(mode, func(t *testing.T) {
			root := setup(t)
			before := hash(t, root)
			r := call(t, root, "save", 0, updated, mode)
			switch mode {
			case "fail-before-publish":
				if r.status != 4 || hash(t, root) != before {
					t.Fatal("failed publication changed committed source")
				}
			case "crash-before-publish":
				if r.exit != 86 || hash(t, root) != before {
					t.Fatal("prepublish crash")
				}
			case "crash-after-publish":
				if r.exit != 87 {
					t.Fatal("postpublish crash")
				}
			case "unknown-after-publish":
				if r.status != 6 {
					t.Fatal("lost durable receipt")
				}
			}
			loaded := call(t, root, "load", 0, nil, "")
			want := initial
			rev := uint64(0)
			if mode == "crash-after-publish" || mode == "unknown-after-publish" {
				want = updated
				rev = 1
			}
			if loaded.status != 0 || loaded.revision != rev || !bytes.Equal(loaded.payload, want) {
				t.Fatal("deterministic restart")
			}
			prior := call(t, root, "prior", 0, nil, "")
			if prior.status != 0 || !bytes.Equal(prior.payload, initial) {
				t.Fatal("previous commit unavailable")
			}
			if rev == 0 {
				if call(t, root, "save", 0, updated, "").status != 0 {
					t.Fatal("staging recovery")
				}
			} else {
				if call(t, root, "save", 0, initial, "").status != 3 {
					t.Fatal("duplicate retry overwrote committed revision")
				}
			}
		})
	}
	t.Run("truncation-and-explicit-prior", func(t *testing.T) {
		root := setup(t)
		if call(t, root, "save", 0, updated, "").status != 0 {
			t.Fatal("setup")
		}
		path := filepath.Join(root, "catalog.vws")
		os.Chmod(path, 0600)
		if e := os.Truncate(path, 16); e != nil {
			t.Fatal(e)
		}
		os.Chmod(path, 0400)
		before := hash(t, root)
		if call(t, root, "load", 0, nil, "").status != 2 || hash(t, root) != before {
			t.Fatal("corruption overwritten")
		}
		if r := call(t, root, "prior", 0, nil, ""); r.status != 0 || !bytes.Equal(r.payload, initial) {
			t.Fatal("valid prior lost")
		}
	})
	t.Run("corrupt-page", func(t *testing.T) {
		root := setup(t)
		path := filepath.Join(root, "catalog.vws")
		data, _ := os.ReadFile(path)
		data[4096] ^= 0x40
		os.Chmod(path, 0600)
		os.WriteFile(path, data, 0400)
		os.Chmod(path, 0400)
		before := hash(t, root)
		if call(t, root, "load", 0, nil, "").status != 2 || hash(t, root) != before {
			t.Fatal("corrupt page admitted or overwritten")
		}
	})
	t.Run("future-schema-preserved", func(t *testing.T) {
		root := t.TempDir()
		os.Chmod(root, 0700)
		r := call(t, root, "create", 0, initial, "future-schema")
		if r.status != 0 {
			t.Fatal("future fixture creation")
		}
		before := hash(t, root)
		if call(t, root, "load", 0, nil, "").status != 5 || hash(t, root) != before {
			t.Fatal("future schema changed")
		}
	})
	t.Run("large-bounded-payload", func(t *testing.T) {
		root := setup(t)
		large := bytes.Repeat([]byte("SYNTHETIC-WORKSPACE"), 10000)
		r := call(t, root, "save", 0, large, "")
		if r.status != 0 {
			t.Fatal("large commit", r.status)
		}
		r = call(t, root, "load", 0, nil, "")
		if r.status != 0 || !bytes.Equal(r.payload, large) {
			t.Fatal("large restore")
		}
		before := hash(t, root)
		if r = call(t, root, "save", 1, make([]byte, 256*1024+1), ""); r.status != 1 || hash(t, root) != before {
			t.Fatal("capacity limit")
		}
	})
	t.Run("sidecar-refusal", func(t *testing.T) {
		root := setup(t)
		before := hash(t, root)
		write(t, filepath.Join(root, "catalog.vws-wal"), "retained")
		if call(t, root, "load", 0, nil, "").status != 7 || hash(t, root) != before {
			t.Fatal("sidecar admitted or erased")
		}
	})
	t.Run("concurrent-writers", func(t *testing.T) {
		root := setup(t)
		results := make(chan workerResult, 2)
		for i := 0; i < 2; i++ {
			go func() {
				result := workerResult{status: ^uint64(0)}
				defer func() { results <- result }()
				result = call(t, root, "save", 0, updated, "")
			}()
		}
		a, b := <-results, <-results
		if !((a.status == 0 && b.status == 3) || (a.status == 3 && b.status == 0)) {
			t.Fatal("unserialized writers", a.status, b.status)
		}
	})
	t.Run("profile-isolation", func(t *testing.T) {
		a, b := setup(t), setup(t)
		if call(t, a, "save", 0, updated, "").status != 0 {
			t.Fatal("save")
		}
		if r := call(t, b, "load", 0, nil, ""); r.status != 0 || !bytes.Equal(r.payload, initial) {
			t.Fatal("separate roots mixed")
		}
	})
}
