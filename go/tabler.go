package tabler

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
)

type Table []map[string]string

func (table Table) Write(fileName string) (err error) {
	f, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer f.Close()
	for _, entry := range table {
		for key, value := range entry {
			fmt.Fprintf(f, "%%%%%s:\n%s\n%%%%\n", key, value)
		}
		fmt.Fprintf(f, "\n")
	}
	return nil
}

func addKey(kv map[string]string, key, value *string) {
	*value = strings.TrimSpace(*value)
	kv[*key] = *value
	*key = ""
	*value = ""
}

func parseTable(data []byte) (table Table, err error) {
	// True if we have just seen "\n":
	line_start := true
	// True if we have seen key:
	have_key := false
	// True if we have seen %% but not finished parsing the key.
	multi_key := false
	// True if we have seen "%%key:" and not yet seen the ending %%:
	multi_line := false
	// First character of line was %.
	first_percent := false
	// In a multi-line construction, we've seen the end of the construction but not the new line yet.
	end_multi_line := false
	// The most recently-seen key
	var key string
	// The most recently-seen value
	var value string
	// In a comment
	comment := false
	kv := make(map[string]string)
	dstring := string(data)
	/* Line number, for error messages. */
	line := 0
	for _, b := range dstring {
		if line_start && b == '%' {
			first_percent = true
			line_start = false
			continue
		}
		if first_percent && b == '%' {
			if multi_line {
				multi_line = false
				if len(key) > 0 && len(value) > 0 {
					addKey(kv, &key, &value)
					have_key = false
				}
				multi_line = false
				end_multi_line = true
				continue
			}
			if multi_key {
				return nil, errors.New(fmt.Sprintf("Found %%%% looking for key for multiline at line %d", line))
			}
			multi_key = true
			first_percent = false
			continue
		}
		first_percent = false
		if line_start && b == '\n' {
			line++
			if multi_line {
				value += string(b)
				continue
			}
			if len(kv) > 0 {
				// Add the current set of key-value pairs
				table = append(table, kv)
				kv = make(map[string]string)
			}
			continue
		}
		if line_start && !multi_line && b == '#' {
			comment = true
			line_start = false
			continue
		}
		if comment {
			if b == '\n' {
				line++
				comment = false
				line_start = true
			}
			continue
		}
		if b == ':' {
			if multi_line || have_key {
				value += string(b)
				continue
			}
			if len(key) == 0 {
				return nil, errors.New("colon at start of line")
			}
			if multi_key {
				multi_line = true
				multi_key = false
			}
			have_key = true
			continue
		}
		if b == '\n' {
			line++
			line_start = true
			if multi_line {
				value += string(b)
				continue
			}
			if multi_key {
				return nil, errors.New(fmt.Sprintf("Line %d: colon at end of key '%s' not found", line,
					key))
			}
			if have_key {
				if len(key) == 0 {
					return nil, errors.New("Empty key")
				}
				addKey(kv, &key, &value)
				have_key = false
				continue
			}
			if end_multi_line {
				end_multi_line = false
				continue
			}
			return nil, errors.New(fmt.Sprintf("Line %d: no key found", line))
		}
		line_start = false
		if !have_key {
			key += string(b)
		} else {
			value += string(b)
		}
	}
	if len(kv) != 0 {
		table = append(table, kv)
	}
	return table, nil
}

func Read(r io.Reader) (table Table, err error) {
	data, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}
	return parseTable(data)
}

func ReadFile(fileName string) (table Table, err error) {
	data, err := ioutil.ReadFile(fileName)
	if err != nil {
		return nil, err
	}
	return parseTable(data)
}
