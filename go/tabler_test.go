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

func TestComment(t *testing.T) {
	cfile := "comment.txt"
	ctable, err := ReadFile(cfile)
	if err != nil {
		t.Errorf("Could not read %s: %s", cfile, err)
		return
	}
	if len(ctable) != 2 {
		t.Errorf("Wrong number of entries %d in table", len(ctable))
		return
	}
	if ctable[0]["a"] != "b" {
		t.Errorf("Failed to read table after comment correctly")
	}
	if ctable[1]["g"] != "h" {
		t.Errorf("Failed to read table after comment correctly")
	}
	ffile := "fork.txt"
	ftable, ferr := ReadFile(ffile)
	if ferr != nil {
		t.Errorf("Could not read %s: %s", ffile, ferr)
		return
	}
	if len(ftable) != 3 {
		t.Errorf("Wrong number of entries %d in table", len(ftable))
		return
	}
	if ftable[1]["b"] != "q" {
		t.Errorf("Failed to read table after comment correctly, got %s",
			ftable[1]["b"])
	}

}
