// base-agentic-coding のアプリ本体。
// 標準ライブラリのみで動く最小構成の HTTP サーバー。
// /healthz で自身の稼働確認、/db で DB への TCP 接続確認を行う。
package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"time"
)

// getenv は環境変数を取得し、未設定ならデフォルト値を返す。
func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func main() {
	addr := ":" + getenv("APP_PORT", "8080")
	dbHost := getenv("DB_HOST", "db")
	dbPort := getenv("DB_PORT", "5432")

	mux := http.NewServeMux()

	// アプリ自身の死活監視用エンドポイント。
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	// DB への到達性を TCP 接続で確認するエンドポイント。
	mux.HandleFunc("/db", func(w http.ResponseWriter, r *http.Request) {
		target := net.JoinHostPort(dbHost, dbPort)
		conn, err := net.DialTimeout("tcp", target, 3*time.Second)
		if err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprintf(w, "db unreachable (%s): %v\n", target, err)
			return
		}
		_ = conn.Close()
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "db reachable (%s)\n", target)
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "base-agentic-coding app")
	})

	srv := &http.Server{
		Addr:         addr,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("listening on %s (db=%s:%s)", addr, dbHost, dbPort)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
