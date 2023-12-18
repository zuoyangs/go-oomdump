package main

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/tencentyun/cos-go-sdk-v5"
)

func upload(wg *sync.WaitGroup, c *cos.Client, files <-chan string) {
	defer wg.Done()
	for file := range files {
		now := time.Now()
		formattedDate := now.Format("2006.01.02-15.04.05")
		name := "Shopping_Cart" + "/" + formattedDate + "/" + file
		fd, err := os.Open(file)
		if err != nil {
			//ERROR
			continue
		}
		_, err = c.Object.Put(context.Background(), name, fd, nil)
		if err != nil {
			//ERROR
		}
	}
}
func main() {
	u, _ := url.Parse("oss.xxxx.com")
	b := &cos.BaseURL{BucketURL: u}
	c := cos.NewClient(b, &http.Client{
		Transport: &cos.AuthorizationTransport{
			SecretID:  "xxxx",
			SecretKey: "xxxx",
		},
	})

	// 多线程批量上传文件
	filesCh := make(chan string, 10)
	var filePaths []string

	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() {
			filename := info.Name()
			if strings.HasPrefix(filename, "dump-jj") && strings.HasSuffix(filename, ".hprof") {
				filePaths = append(filePaths, path)
			} else if strings.HasPrefix(filename, "gc-jj") && strings.HasSuffix(filename, ".log") {
				filePaths = append(filePaths, path)
			}
		}

		return nil
	})

	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	var wg sync.WaitGroup
	threadpool := 10
	for i := 0; i < threadpool; i++ {
		wg.Add(1)
		go upload(&wg, c, filesCh)
	}
	for _, filePath := range filePaths {
		filesCh <- filePath
	}
	close(filesCh)
	wg.Wait()
}
