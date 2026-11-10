package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
)

type workspaceCase struct {
	ID       string   `json:"id"`
	Status   string   `json:"status"`
	Evidence []string `json:"evidence"`
	Reason   string   `json:"reason"`
	Owner    string   `json:"owner"`
}

func verifyWorkspaceMatrix(root, manifest, matrix string) []Check {
	const maxSize = 256 * 1024
	info, err := os.Stat(matrix)
	if err != nil || !info.Mode().IsRegular() || info.Size() > maxSize {
		return []Check{{"matrix", "failed", "matrix must be a bounded regular file"}}
	}
	file, err := os.Open(matrix)
	if err != nil {
		return []Check{{"matrix", "failed", "matrix unavailable"}}
	}
	defer file.Close()
	decoder := json.NewDecoder(io.LimitReader(file, maxSize+1))
	decoder.DisallowUnknownFields()
	var cases []workspaceCase
	var extra any
	if decoder.Decode(&cases) != nil || decoder.Decode(&extra) != io.EOF {
		return []Check{{"matrix", "failed", "invalid case records"}}
	}

	manifestChecks := evidence(root, manifest)
	verified := make(map[string]bool)
	for _, check := range manifestChecks {
		verified[check.Name] = check.Status == "passed"
	}
	checks := []Check{{"evidence-manifest", report("evidence", manifestChecks).Status, ""}}
	required := make(map[string]bool)
	for i := 1; i <= 20; i++ {
		required[fmt.Sprintf("F7-%02d", i)] = true
	}
	for _, row := range cases {
		check := Check{row.ID, "passed", "case record valid (" + row.Status + ")"}
		reject := func(reason string) { check.Status, check.Reason = "failed", reason }
		if !required[row.ID] {
			reject("unknown or duplicate WS-F7 case")
		}
		delete(required, row.ID)
		switch row.Status {
		case "passed", "failed":
			if len(row.Evidence) == 0 {
				reject("executed result has no evidence")
			}
		case "blocked", "not_executed", "skipped", "not_applicable":
			if strings.TrimSpace(row.Reason) == "" || strings.TrimSpace(row.Owner) == "" {
				reject("unexecuted or inapplicable case requires reason and owner")
			}
		default:
			reject("invalid status")
		}
		for _, artifact := range row.Evidence {
			if !verified[artifact] {
				reject("evidence missing from verified manifest")
			}
		}
		checks = append(checks, check)
	}
	for id := range required {
		checks = append(checks, Check{id, "failed", "required case missing"})
	}
	return checks
}
