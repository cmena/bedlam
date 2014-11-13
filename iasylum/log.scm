;;; Code by Igor Hjelmstrom Vinhas Ribeiro - this is licensed under GNU GPL v2.

(require-extension (lib iasylum/iasylum))

(module iasylum/log
  (
   make-logger
   make-human-logger
   make-empty-logger
   get-global-logger-to-this-thread
   set-global-logger-to-this-thread!
   with-logger

   get-thread-info
   log-o
   get-timestamp
   make-mark-logger
   timestamped-log
   log-trace
   log-debug
   log-info
   log-warn
   log-error
   log-fatal)
  
  (define (log-o m)
    (j "System.out.println(m); System.out.flush();" `((m ,(->jstring m))))
    (void))
  
  (define (get-timestamp)
    (->string (j "new java.text.SimpleDateFormat(\"yyyy-MM-dd HH:mm:ss,SSS\").format(new java.util.Date());")))
  
  (define make-mark-logger (lambda (mark) (lambda m (timestamped-log mark m))))

  (define (get-thread-info)
    (->string (j "Thread.currentThread().getName();")))
  
  (define (timestamped-log mark m)
    (log-o (iasylum-write-string (list mark (get-thread-info) (get-timestamp) m))))

  (let-syntax ((define-log-fn (syntax-rules ()
                                [(_ name level-symbol)
                                 (define name
                                   (lambda params
                                     (apply (get-global-logger-to-this-thread)
                                            (append (list level-symbol) params))))])))
    (begin
      (define-log-fn log-trace 'trace)
      (define-log-fn log-debug 'debug)
      (define-log-fn log-info 'info)
      (define-log-fn log-warn 'warn)
      (define-log-fn log-error 'error)
      (define-log-fn log-fatal 'fatal)))
  
  (define (get-global-logger-to-this-thread)
    (->scm-object (j "iu.M.d.get(\"logger-global_48729\").get();")))

  (define (set-global-logger-to-this-thread! logger)
    (j "iu.M.d.get(\"logger-global_48729\").set(newlogger);"
       `((newlogger ,(->jobject logger)))))

  ;;
  ;; It is useful when you will use the same information several times,
  ;; e.g. transaction-id.
  ;;
  ;; Example:
  ;; (make-logger <module-name> <transaction-id> <ip> <any-important-information> ...)
  ;; => logger
  ;;
  ;; using logger:
  ;; (logger 'trace "message1" "message2")
  ;; => ("TRACE" "[thread=9]" "2014-05-20 05:11:06.506"
  ;;             (<module-name> <transaction-id> <ip>
  ;;              <any-important-information> ... "message1" "message2"))
  ;;
  (define-syntax make-logger
    (syntax-rules ()
      ((_ <custom-info> ...)
       (let* ((log-trace (make-mark-logger "TRACE"))
              (log-debug (make-mark-logger "DEBUG"))
              (log-info  (make-mark-logger "INFO"))
              (log-warn  (make-mark-logger "WARN"))
              (log-error (make-mark-logger "ERROR"))
              (log-fatal (make-mark-logger "FATAL"))
              (log-hash (alist->hashtable `((trace . ,log-trace)
                                            (debug . ,log-debug)
                                            (info  . ,log-info)
                                            (warn  . ,log-warn)
                                            (error . ,log-error)
                                            (fatal . ,log-fatal)))))
         (lambda (level . message)
           (apply (cut (hashtable/get log-hash level log-error)
                       <custom-info> ... <...>) message))))))

  (define-syntax make-human-logger
    (syntax-rules ()
      ((_ min-level)
       (let ((level-hash (alist->hashtable `((trace . 0)
                                             (debug . 1)
                                             (info  . 2)
                                             (warn  . 3)
                                             (error . 4)
                                             (fatal . 5)))))
         (lambda (level . message)
           (if (>= (hashtable/get level-hash level 0)
                   (hashtable/get level-hash min-level 0))
               (apply d (add-between-elements "\n" (append (list (string-append* "______ "
                                                                                 (string-upcase (symbol->string level))
                                                                                 " ________________________"
                                                                                 " (" (get-thread-info) ")"
                                                                                 "\n"))
                                                           message (list "\n"))))))))))

  (define (make-empty-logger)
    (lambda (level . message) #t))

  (define-syntax with-logger
    (syntax-rules ()
      ((_ logger body ...)
       (let ((old-logger (get-global-logger-to-this-thread)))
         (dynamic-wind (lambda () (set-global-logger-to-this-thread! logger))
                       (lambda () body ...)
                       (lambda () (set-global-logger-to-this-thread! old-logger)))))))

  (j "globalLogger = new ThreadLocal() {
             protected Object initialValue() {
                 return defaultlogger;
             }
      };

      iu.M.d.putIfAbsent(\"logger-global_48729\", globalLogger);"
     `((defaultlogger ,(->jobject (make-logger)))))
  
  )
  
