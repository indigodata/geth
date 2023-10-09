package indigo

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/log" // Importing the Geth logger
)

const (
	bufferSize   = 200
	flushTimeout = 5 * time.Second
)

var syncMode string
var dataDir string

func SetSyncMode(mode string) {
	syncMode = mode
}

func SetDataDir(dir string) {
	dataDir = dir
}

var loggersMap sync.Map

type CsvLogger struct {
	mainDir    string
	subDir     string
	logCh      chan []string
	mu         sync.Mutex
	buffer     [][]string
	flushTimer *time.Timer
}

func getOrCreateLogger(subDir string) *CsvLogger {
	mainDir := "network_feed"
	key := mainDir + ":" + subDir
	if logger, exists := loggersMap.Load(key); exists {
		return logger.(*CsvLogger)
	}

	if dataDir == "" {
		log.Error("dataDir is not set.")
		return nil
	}

	fullMainDir := filepath.Join(dataDir, mainDir)

	l := &CsvLogger{
		mainDir:    fullMainDir,
		subDir:     subDir,
		logCh:      make(chan []string, bufferSize),
		buffer:     make([][]string, 0, bufferSize),
		flushTimer: time.NewTimer(flushTimeout),
	}

	go l.listen()

	loggersMap.Store(key, l)
	return l
}

func (l *CsvLogger) listen() {
	for {
		select {
		case entry := <-l.logCh:
			l.buffer = append(l.buffer, entry)
			if len(l.buffer) >= bufferSize {
				log.Info(fmt.Sprintf("INDIGO buffer size limit %v", l.subDir))
				l.flushBuffer()
			}
		case <-l.flushTimer.C:
			log.Info(fmt.Sprintf("INDIGO 5 second buffer %v", l.subDir))
			l.flushBuffer()
			l.flushTimer.Reset(flushTimeout)
		}
	}
}

func (l *CsvLogger) flushBuffer() {
	l.mu.Lock()
	defer l.mu.Unlock()

	if len(l.buffer) == 0 {
		return
	}

	filename := l.currentFilename()

	dir := filepath.Dir(filename)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, 0755); err != nil {
			fmt.Printf("Error creating directories: %v\n", err)
			return
		}
	}

	file, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("Error opening file: %v\n", err)
		return
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	for _, entries := range l.buffer {
		line := fmt.Sprintf("\"%s\"\n", join(entries, "\",\""))
		writer.WriteString(line)
	}
	writer.Flush()

	// Clear the buffer
	l.buffer = l.buffer[:0]
}

func Log(subDir string, entries ...string) {
	logger := getOrCreateLogger(subDir)
	logger.logCh <- entries
}

func join(strs []string, sep string) string {
	var result string
	for i, s := range strs {
		if i > 0 {
			result += sep
		}
		result += s
	}
	return result
}

func (l *CsvLogger) currentFilename() string {
	now := time.Now().UTC()
	return fmt.Sprintf("%s/%s/%d%02d%02d-%02d.csv", l.mainDir, l.subDir, now.Year(), now.Month(), now.Day(), now.Hour())
}
