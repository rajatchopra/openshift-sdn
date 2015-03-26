package server

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"path"
	"sync"
	"time"
)

// Server is a http.Handler which exposes netutils functionality over HTTP.
type Server struct {
	ipam IpamInterface
	mux  *http.ServeMux
}

type TLSOptions struct {
	Config   *tls.Config
	CertFile string
	KeyFile  string
}

// ListenAndServeNetutilServer initializes a server to respond to HTTP network requests on the Kubelet.
func ListenAndServeNetutilServer(ipam IpamInterface, address net.IP, port uint, tlsOptions *TLSOptions, enableDebuggingHandlers bool) {
	glog.V(1).Infof("Starting to listen on %s:%d", address, port)
	handler := NewServer(ipam, enableDebuggingHandlers)
	s := &http.Server{
		Addr:           net.JoinHostPort(address.String(), strconv.FormatUint(uint64(port), 10)),
		Handler:        &handler,
		ReadTimeout:    5 * time.Minute,
		WriteTimeout:   5 * time.Minute,
		MaxHeaderBytes: 1 << 20,
	}
	if tlsOptions != nil {
		s.TLSConfig = tlsOptions.Config
		glog.Fatal(s.ListenAndServeTLS(tlsOptions.CertFile, tlsOptions.KeyFile))
	} else {
		glog.Fatal(s.ListenAndServe())
	}
}

// IpamInterface contains all the methods required by the server.
type IpamInterface interface {
	GetSubnet() string
	GetIP() string
	CheckInIP(ip string)
	CheckInSubnet(sub string)
	GetStats() string
}

// NewServer initializes and configures a kubelet.Server object to handle HTTP requests.
func NewServer(ipam IpamInterface, enableDebuggingHandlers bool) Server {
	server := Server{
		ipam: ipam,
		mux:  http.NewServeMux(),
	}
	server.InstallDefaultHandlers()
	if enableDebuggingHandlers {
		server.InstallDebuggingHandlers()
	}
	return server
}

// InstallDefaultHandlers registers the default set of supported HTTP request patterns with the mux.
func (s *Server) InstallDefaultHandlers() {
	s.mux.HandleFunc("/netutils/subnet", s.handleSubnet)
	s.mux.HandleFunc("/netutils/ip", s.handleIP)
	s.mux.HandleFunc("/netutils/gateway", s.handleGateway)
	s.mux.HandleFunc("/stats/", s.handleStats)
}

// error serializes an error object into an HTTP response.
func (s *Server) error(w http.ResponseWriter, err error) {
	msg := fmt.Sprintf("Internal Error: %v", err)
	glog.Infof("HTTP InternalServerError: %s", msg)
	http.Error(w, msg, http.StatusInternalServerError)
}

// handleSubnet handles gateway requests
func (s *Server) handleSubnet(w http.ResponseWriter, req *http.Request) {
	w.Header().Add("Content-type", "application/json")
	w.Write("Not implemented")
	return
}

// handleGateway handles gateway requests
func (s *Server) handleGateway(w http.ResponseWriter, req *http.Request) {
	w.Header().Add("Content-type", "application/json")
	w.Write("Not implemented")
	return
}

// handleIP handles IP requests
func (s *Server) handleIP(w http.ResponseWriter, req *http.Request) {
	w.Header().Add("Content-type", "application/json")
	w.Write("Not implemented")
	return
}

// handleStats handles stats requests against the Kubelet.
func (s *Server) handleStats(w http.ResponseWriter, req *http.Request) {
	w.Header().Add("Content-type", "application/json")
	w.Write("Not implemented")
	return
}

// ServeHTTP responds to HTTP requests on the Kubelet.
func (s *Server) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	defer httplog.NewLogged(req, &w).StacktraceWhen(
		httplog.StatusIsNot(
			http.StatusOK,
			http.StatusMovedPermanently,
			http.StatusTemporaryRedirect,
			http.StatusNotFound,
			http.StatusSwitchingProtocols,
		),
	).Log()
	s.mux.ServeHTTP(w, req)
}
