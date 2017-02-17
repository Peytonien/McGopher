;;; gopher.lisp

(defpackage #:mcgopher.gopher
  (:use #:cl
        #:mcgopher.utils
        #:usocket)
  (:export #:plain-text
           #:directory-list
           #:cso-search-query
           #:error-message
           #:binhex-text
           #:binary-archive
           #:uuencoded-text
           #:search-query
           #:telnet-session-pointer
           #:binary-file
           #:gif-image
           #:html-file
           #:information
           #:unspecified-image
           #:audio
           #:tn3270-session-pointer
           #:category
           #:contents
           #:location
           #:host
           #:gopher-port

           #:gopher-goto))

(in-package #:mcgopher.gopher)

;; Gopher content types

(defvar *content-types*
  '((#\0 . plain-text)
    (#\1 . directory-list)
    (#\2 . cso-search-query)
    (#\3 . error-message)
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

(defun lookup (type)
  (cdr (assoc type *content-types*)))

(defclass content ()
  ((contents :initarg :contents :accessor contents)
   (location :initarg :location :accessor location)
   (host :initarg :host :accessor host)
   (gopher-port :initarg :gopher-port :accessor gopher-port)))

(defclass plain-text             (content) ())
(defclass directory-list         (content) ())
(defclass cso-search-query       (content) ())
(defclass error-message          (content) ())
(defclass binhex-text            (content) ())
(defclass binary-archive         (content) ())
(defclass uuencoded-text         (content) ())
(defclass search-query           (content) ())
(defclass telnet-session-pointer (content) ())
(defclass binary-file            (content) ())
(defclass gif-image              (content) ())
(defclass html-file              (content) ())
(defclass information            (content) ())
(defclass unspecified-image      (content) ())
(defclass audio                  (content) ())
(defclass tn3270-session-pointer (content) ())

(defun read-item (stream)
  "Given a stream containing a Gopher response, returns a Gopher item."
  (when (peek-char nil stream nil nil)
    (let ((category (read-char stream)))
      (make-instance (lookup category)
                     :contents (read-until #\Tab stream)
                     :location (read-until #\Tab stream)
                     :host (read-until #\Tab stream)
                     :gopher-port (remove #\Return (read-until #\Newline stream))))))

(defun read-items (stream)
  "Reads gopher items from a stream"
  (loop for item = (read-item stream)
     until (null item)
     collect item))

(defun response-to-string (response)
  "Reads from a stream, returning the contents as string."
  (with-output-to-string (stream)
    (loop for line = (read-line response nil)
       while line do (format stream "~A~%" line))))

(defun fix-formatting (string)
  "Removes tabs and #\Return from a string."
  (tabs-to-spaces (remove #\Return string)))

(defun gopher-item-to-address (item)
  "Converts a Gopher item to an address"
  (format nil "~A/~A~A"
          (gopher-host item)
          (gopher-category item)
          (gopher-location item)))

(defun gopher-goto (address &optional (port 70))
  "Given an address, returns a list of Gopher items."
  (let* ((split-address (ppcre:split "[^a-zA-Z0-9_\\-.]" address :limit 3))
         (host (first split-address))
         (location (cat "/" (third split-address))))
    (handler-case
        (with-connected-socket (socket (socket-connect host port :timeout 15))
          (let ((stream (socket-stream socket)))
            (format stream "~A" location)
            (force-output stream)
            (read-items stream)))
      (error () (list (make-instance 'error-message :contents "Page not found."))))))
