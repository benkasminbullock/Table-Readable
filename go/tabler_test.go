package tabler

import "testing"

func TestTable(t *testing.T) {
	var table Table
	kv1 := map[string]string{
		"baby":  "chops",
		"monty": "baby",
		"nice":  "crocodile",
	}
	table = append(table, kv1)
	tfile := "test-table.txt"
	table.Write(tfile)
	intable, err := ReadFile(tfile)
	if err != nil {
		t.Errorf("Could not read %s: %s", tfile, err)
	}
	if intable[0]["baby"] != "chops" {
		t.Errorf("Did not successfully round-trip, got %s", intable[0]["baby"])
	}
	if intable[0]["nice"] != "crocodile" {
		t.Errorf("Did not successfully round-trip, got %s", intable[0]["nice"])
	}
}
