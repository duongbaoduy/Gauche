;;;
;;; uri.scm - parse and construct URIs
;;;  
;;;   Copyright (c) 2000-2003 Shiro Kawai, All rights reserved.
;;;   
;;;   Redistribution and use in source and binary forms, with or without
;;;   modification, are permitted provided that the following conditions
;;;   are met:
;;;   
;;;   1. Redistributions of source code must retain the above copyright
;;;      notice, this list of conditions and the following disclaimer.
;;;  
;;;   2. Redistributions in binary form must reproduce the above copyright
;;;      notice, this list of conditions and the following disclaimer in the
;;;      documentation and/or other materials provided with the distribution.
;;;  
;;;   3. Neither the name of the authors nor the names of its contributors
;;;      may be used to endorse or promote products derived from this
;;;      software without specific prior written permission.
;;;  
;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;;;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;;;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;  
;;;  $Id: uri.scm,v 1.14 2003-07-05 03:29:12 shirok Exp $
;;;

;; Main reference:
;; RFC2396 Uniform Resource Identifiers (URI): Generic Syntax
;;  <ftp://ftp.isi.edu/in-notes/rfc2396.txt>

;; Historical:
;; RFC1738 Uniform Resource Locators
;;  <ftp://ftp.isi.edu/in-notes/rfc1738.txt>
;; RFC1808 Relative Uniform Resource Locators
;;  <ftp://ftp.isi.edu/in-notes/rfc1808.txt>
;; RFC2368 The mailto URL Scheme
;;  <ftp://ftp.isi.edu/in-notes/rfc2368.txt>

(define-module rfc.uri
  (use srfi-13)
  (use gauche.regexp)
  (export uri-scheme&specific uri-decompose-hierarchical
          uri-decompose-authority
          uri-compose
          uri-decode uri-decode-string
          uri-encode uri-encode-string
          )
  )
(select-module rfc.uri)

;;==============================================================
;; Generic parser
;;

;; Splits URI scheme and the scheme specific part from given URI.
;; If URI doesn't follow the generic URI syntax, it is regarded
;; as a relative URI and #f is returned for the scheme.
;; The escaped characters of the scheme specific part is not unescaped;
;; their interpretation is dependent on the scheme.

(define (uri-scheme&specific uri)
  (cond ((#/^([A-Za-z][A-Za-z0-9+.-]*):/ uri)
         => (lambda (m)
              (values (string-downcase (m 1)) (m 'after))))
        (else (values #f uri))))

(define (uri-decompose-hierarchical specific)
  (rxmatch-if
      (#/^(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$/ specific)
      (#f #f authority path #f query #f fragment)
    (values authority path query fragment)
    (values #f #f #f #f)))

(define (uri-decompose-authority authority)
  (rxmatch-if
      (#/^([^@]*@)?([^:]*)(:(\d*))?$/ authority)
      (#f userinfo host #f port)
    (values userinfo host port)
    (values #f #f #f)))

;;==============================================================
;; Generic constructor
;;

(define (uri-compose . args)
  (let-keywords* args ((scheme     #f)
                       (userinfo   #f)
                       (host       #f)
                       (port       #f)
                       (authority  #f)
                       (path       #f)
                       (path*      #f)
                       (query      #f)
                       (fragment   #f)
                       (specific   #f))
    (with-output-to-string
      (lambda ()
        (when scheme (display scheme) (display ":"))
        (if specific
            (display specific)
            (begin
              (display "//")
              (if authority
                  (begin (display authority))
                  (begin
                    (when userinfo (display userinfo) (display "@"))
                    (when host     (display host))
                    (when port     (display ":") (display port))))
              (if path*
                  (begin
                    (unless (string-prefix? "/" path*) (display "/"))
                    (display path*))
                  (begin
                    (if path
                        (begin (unless (string-prefix? "/" path) (display "/"))
                               (display path))
                        (display "/"))
                    (when query (display "?") (display query))
                    (when fragment (display "#") (display fragment))))
              ))
        ))
    ))

;;==============================================================
;; Relative -> Absolute
;;


;;==============================================================
;; Encoding & decoding
;;
;;  NB. Which character to encode, and when to encode/decode depend on
;;  the semantics of specific URI scheme.
;;  These procedures provides basic building components.

(define (uri-decode . args)
  (define cgi-decode (get-keyword :cgi-decode args #f))
  (let loop ((c (read-char)))
    (cond ((eof-object? c))
          ((char=? c #\%)
           (let ((c1 (read-char)))
             (cond ((digit->integer c1 16)
                    => (lambda (i1)
                         (let ((c2 (read-char)))
                           (cond ((digit->integer c2 16)
                                  => (lambda (i2)
                                       (write-byte (+ (* i1 16) i2))
                                       (loop (read-char))))
                                 (else (write-char c)
                                       (write-char c1)
                                       (loop c2))))))
                   (else (write-char c)
                         (loop c1)))))
          ((char=? c #\+)
           (if cgi-decode (write-char #\space) (write-char #\+))
           (loop (read-char)))
          (else (write-char c)
                (loop (read-char)))
          )))

(define (uri-decode-string string . args)
  (with-string-io string (lambda () (apply uri-decode args))))

;; Default set of characters that can be passed without escaping.
;; See 2.3 "Unreserved Characters" of RFC 2396.
(define *uri-unreserved-char-set* #[-_.!~*'()0-9A-Za-z])

;; NB: Converts byte by byte, instead of chars, to avoid complexity
;; from different character encodings (suggested by Fumitoshi UKAI).
;; 'noescape' char-set is only valid in ASCII range.  All bytes
;; larger than #x80 are encoded unconditionally.
(define (uri-encode . args)
  (let ((echars (get-keyword :noescape args *uri-unreserved-char-set*)))
    (let loop ((b (read-byte)))
      (unless (eof-object? b)
        (if (and (< b #x80)
                 (char-set-contains? echars (integer->char b)))
            (write-byte b) 
            (format #t "%~2,'0x" b))
        (loop (read-byte))))))

(define (uri-encode-string string . args)
  (with-string-io string (lambda () (apply uri-encode args))))

(provide "rfc/uri")
