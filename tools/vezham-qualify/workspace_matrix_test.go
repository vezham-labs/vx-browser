package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

func TestWorkspaceMatrixRequiresCoverageAndVerifiedEvidence(t *testing.T) {
	root := t.TempDir()
	matrix := filepath.Join(root, "matrix.json")
	artifact := filepath.Join(root, "result.txt")
	manifest := filepath.Join(root, "SHA256SUMS")
	write(t, artifact, "observation")
	write(t, manifest, fmt.Sprintf("%x  result.txt\n", sha256.Sum256([]byte("observation"))))
	rows := make([]workspaceCase, 20)
	for i := range rows {
		rows[i] = workspaceCase{ID: fmt.Sprintf("F7-%02d", i+1), Status: "blocked", Reason: "Signing required", Owner: "Release"}
	}
	writeRows := func(rows []workspaceCase) {
		bytes, err := json.Marshal(rows)
		if err != nil {
			t.Fatal(err)
		}
		if err = os.WriteFile(matrix, bytes, 0600); err != nil {
			t.Fatal(err)
		}
	}
	status := func() string { return report("workspace-matrix", verifyWorkspaceMatrix(root, manifest, matrix)).Status }
	writeRows(rows)
	if got := status(); got != "passed" {
		t.Fatalf("complete documented blocked matrix: %s", got)
	}
	writeRows(rows[:19])
	if got := status(); got != "failed" {
		t.Fatalf("missing case: %s", got)
	}
	rows[0].Status = "passed"
	writeRows(rows)
	if got := status(); got != "failed" {
		t.Fatalf("unwitnessed pass: %s", got)
	}
	rows[0].Evidence = []string{"result.txt"}
	writeRows(rows)
	if got := status(); got != "passed" {
		t.Fatalf("witnessed result: %s", got)
	}
	write(t, artifact, "changed")
	if got := status(); got != "failed" {
		t.Fatalf("changed evidence: %s", got)
	}
}
