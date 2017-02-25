;;; gopher.lisp


(defpackage #:mcgopher.gopher
  (:use #:cl
        #:iolib
        #:files-and-folders
        #:alexandria
        #:mcgopher.config
        #:mcgopher.utils)
  (:export ;; Gopher Content Type Classes
           #:content
           #:plain-text
           #:directory-list
           #:cso-search-query
           #:page-error
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
           ;; Class Methods
           #:contents
           #:location
           #:host
           #:gopher-port
           ;; Gopher Commands
           #:gopher-goto
           #:goto-text
           #:download
           #:internal-address
           #:content-address))

(in-package #:mcgopher.gopher)

;; Gopher Content Type Classes

(defclass content ()
  ((contents :initarg :contents :accessor contents :initform nil)
   (location :initarg :location :accessor location)
   (host :initarg :host :accessor host)
   (gopher-port :initarg :gopher-port :accessor gopher-port)))

(macrolet ((generate-content-classes ()
             "Create content classes from *content-types*."
             `(progn
                ,@(loop for item in *content-types*
                        for class = (symbolicate (cdr item))
                        collect `(defclass ,class (content) ())))))
  (generate-content-classes))

;; Gopher Commands

(defun lookup (type)
  "Find the associated gopher content type when given a character."
  (intern (string (cdr (assoc type *content-types*))) :mcgopher.gopher))

(defun read-item (stream)
  "Given a stream from a Gopher server, attempts to read a Gopher item."
  (let ((category (lookup (read-char stream nil))))
    (when category
      (make-instance category
                     :contents (or (read-until #\Tab stream) "")
                     :location (read-until #\Tab stream)
                     :host (read-until #\Tab stream)
                     :gopher-port (remove #\Return
                                          (read-until #\Newline stream))))))

(defun read-items (stream)
  "Reads gopher items from a stream"
  (loop for item = (read-item stream)
     until (null item)
     collect item))

(defun fix-formatting (string)
  "Removes tabs and #\Return from a string."
  (tabs-to-spaces (remove #\Return string)))

(defmacro with-address-socket ((var address) &body body)
  "with input from"
  `(let* ((split-address (ppcre:split "[^a-zA-Z0-9_\\-.]" ,address :limit 2))
          (host (first split-address))
          (location (second split-address)))
     (handler-case
         (with-open-socket (,var :connect :active
                                 :address-family :internet
                                 :type :stream
                                 :external-format '(:utf-8 :eol-style :crlf)
                                 :ipv6 nil)
           (connect ,var (lookup-hostname host) :port 70 :wait t)
           (format ,var "/~A~%" (or location "/"))
           (force-output ,var)
           ,@body)
       (hangup ()
         (list (make-instance 'page-error :contents "Server closed connection
                                                    when attempting to write.")))
       (end-of-file ()
         (list (make-instance 'page-error :contents "Server closed connection
                                                    when attempting to read.")))
       (socket-connection-reset-error ()
         (list (make-instance 'page-error :contentes "Connection reset by
                                                     peer.")))
       (socket-connection-refused-error ()
         (list (make-instance 'page-error :contents "Connection refused.")))
       (error ()
         (list (make-instance 'page-error :contents "Unable to load page."))))))

(defun infer-content-type (address)
  "Tries to guess the content type from the address. If it can't find the type
  it is assumed to be a directory listing."
  (let* ((split-address (ppcre:split "[^a-zA-Z0-9_\\-.]" address :limit 3))
         (type (second split-address))
         (class-type (and (= (length type) 1) (lookup (first-elt type)))))
    (if class-type
        (values class-type (remove type split-address :test #'string=))
        (values (lookup #\1) split-address))))

(defun internal-address (content &optional (category #\1))
  "Address used for inferring the content type."
  (format nil "~A/~A~A" (host content) category (or (location content) "")))

(defun content-address (content)
  "Address as read by the Gopher server."
  (format nil "~A/~A" (host content) (location content)))

(defmethod gopher-goto ((object plain-text))
  "Given a plain-text object, reads the linked content into a string."
  (with-address-socket (socket (content-address object))
    (list (fix-formatting (read-stream-content-into-string socket)))))

(defmethod gopher-goto ((object directory-list))
  "Given an address, returns a list of Gopher items."
  (with-address-socket (socket (content-address object))
    (read-items socket)))

(defmethod gopher-goto ((address string))
  "Given an address, returns a list of Gopher items."
  (multiple-value-bind (type split-address)
      (infer-content-type address)
    (gopher-goto (make-instance type :host (car split-address)
                                     :location (format nil "~{~A~^ ~}"
                                                       (cdr split-address))))))

(defun download (address &optional file-name)
  "Saves the server reply to the downloads folder"
  (let* ((name (or file-name (lastcar (ppcre:split "[^a-zA-Z0-9_\\-.]" address))))
         (path (merge-paths *download-folder* name)))
    (with-address-socket (socket address)
      (write-byte-vector-into-file (read-stream-content-into-byte-vector socket)
                                   path :if-exists :supersede))
    (values path)))