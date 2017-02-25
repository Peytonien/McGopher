;; config.lisp

(defpackage #:mcgopher.config
  (:use #:clim #:clim-lisp)
  (:export ;; Gopher Content Types
           #:*content-types*
           #:*downloadable-types*
           #:*external-programs*
           ;; Appearance
           #:*font-size*
           #:*background*
           #:*foreground*
           #:*alt-background*
           #:*alt-foreground*
           ;; Keybindings
           #:*key-previous*
           #:*key-quit*
           #:*key-refresh*
           ;;Misc
           #:*download-folder*
           #:*homepage*))

(in-package #:mcgopher.config)

;; Gopher Content Types

(defconstant *content-types*
  '((#\0 . plain-text)
    (#\1 . directory-list)
    (#\2 . cso-search-query)
    (#\3 . page-error)
    (#\4 . binhex-text)
    (#\5 . binary-archive)
    (#\6 . uuencoded-text)
    (#\7 . search-query)
    (#\8 . telnet-session-pointer)
    (#\9 . binary-file)
    (#\g . gif-image)
    (#\h . html-file)
    (#\i . information)
    (#\I . unspecified-image)
    (#\s . audio)
    (#\T . tn3270-session-pointer)))

(defconstant *downloadable-types*
  '(plain-text binary-archive binary-file gif-image unspecified-image audio))

(defconstant *external-programs*
  '((gif-image         . "feh")
    (unspecified-image . "feh")
    (audio             . "mpv")))

;; Appearance
(defvar *font-size* :large)
(defvar *background* +white+)
(defvar *foreground* +black+)
(defvar *alt-background* +light-gray+)
(defvar *alt-foreground* +black+)

;; Keybindings
(defvar *key-previous* `(:left :meta))
(defvar *key-quit* `(#\q :control))
(defvar *key-refresh* `(:F5))

;; Misc
(defvar *download-folder* #P"~/Downloads")
(defvar *homepage* "gopher.floodgap.com")