package indigo

import (
	"io"
	"os"
	"strings"
)

type Logger struct {
	writer io.Writer
}

var logger = &Logger{writer: os.Stdout}

func WriteLog(input ...string) error {
	_, err := logger.writer.Write([]byte("INDIGO " + strings.Join(input, " ") + "\n"))
	return err
}
