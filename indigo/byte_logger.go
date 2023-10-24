package indigo

import (
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
	"time"
)

type Logger struct {
	writer         io.Writer
	mutex          sync.Mutex
	switchOverTime time.Time
}

var logger *Logger
var dataDir string

func SetDataDir(dir string) {
	dataDir = dir
}

func init() {
	logger = &Logger{switchOverTime: nextSwitchOverTime()}
}

func nextSwitchOverTime() time.Time {
	now := time.Now().UTC()
	return time.Date(now.Year(), now.Month(), now.Day(), now.Hour()+1, 0, 0, 0, now.Location())
}

func (l *Logger) setWriter() {
	l.switchOverTime = nextSwitchOverTime()
	filename := fmt.Sprintf("%s/network_feed/%s.csv", dataDir, time.Now().UTC().Format("20060102-15"))

	file, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		fmt.Printf("Error opening or creating file: %v\n", err)
		return
	}

	l.writer = file
}

func WriteLog(input ...string) error {
	logger.mutex.Lock()
	defer logger.mutex.Unlock()

	// Check if the file is set or if the current time has passed the switchover time
	if logger.writer == nil || time.Now().UTC().After(logger.switchOverTime) {
		logger.setWriter()
	}

	_, err := logger.writer.Write([]byte(strings.Join(input, " ") + "\n"))
	return err
}
