(define-generic-java-method get |get|)
(define-generic-java-method set |set|)

;;nodejs - remote
(define (nodejs-global code)
  (log-trace "About to execute js code" code)
  (let ((result (http-call-post-string/string "http://js:27429/" code)))
    (log-trace "Result" result)
    (if (and result
             (not (string=? "" result)))
        (json->scheme result)
        #f)))

(define* (nodejs code (vars '()))
  (let* ((names-and-values-pair (call-with-values
                                    (lambda () (unzip2 vars))
                                  (lambda (names values) (cons names values))))
         (names (car names-and-values-pair))
         (values (cdr names-and-values-pair))
         (code (format "(function(~a) { return ~a })(~a);"
                       (apply add-between (cons "," names))
                       code
                       (apply add-between (cons "," (map (lambda (v)
                                                           (cond [(number? v)
                                                                  (number->string v)]
                                                                 [else
                                                                  (string-append* "\"" v "\"")]))
                                                         values))))))
    (node-js-global code)))


;; rhino
(define (rhino-create-thread-local-javascript-manager-retriever)
    (let ((tl
           (j "mtl=new ThreadLocal() {
                   protected synchronized Object initialValue() {                       
                       return new javax.script.ScriptEngineManager().getEngineByName(\"rhino\");
                   }
               }; mtl;")))
      (lambda ()
        (let ((result (get tl)))
          result))))

(define rhino-get-local-javascript-manager)
(define js-rhino)
(define (rhino-js-manager)  (j "new javax.script.ScriptEngineManager().getEngineByName(\"rhino\");"))


;; v8
(define js)
(define get-local-javascript-manager)
(define js-v8)
(define (create-thread-local-javascript-manager-retriever)
    (let ((tl
           (j "mtlv8=new ThreadLocal() {
                   protected synchronized Object initialValue() {                       
                       return com.eclipsesource.v8.V8.createV8Runtime();
                   }
               }; mtlv8;")))
      (lambda ()
        (let ((result (get tl)))
          result))))

(define (js-manager)  (j "return com.eclipsesource.v8.V8.createV8Runtime();"))


;; rhino
(set! rhino-get-local-javascript-manager (rhino-create-thread-local-javascript-manager-retriever))
(set! js-rhino
  (lambda*
   (code (vars #f) (manager (rhino-get-local-javascript-manager)))
   ;(d/n "Will run code: (((((" code "))))) saved to " (save-to-somewhere code))
   ;(d/n "vars: " vars)
   (j                       
       "import javax.script.*;
        cx = org.mozilla.javascript.Context.enter();
        cx.setOptimizationLevel(-1);"        
       `((manager ,manager)))
  
  (when vars
    (for-each
     (lambda (v)
       (match-let ( ( (vname vvalue) v ) )
                  (begin
                    (let* ((sname (if (string? vname) vname (symbol->string vname)))
                           (name (->jstring sname )))
                      ;(d/n "saving " sname " to " (save-to-somewhere vvalue))
                      (j "manager.put(jsobjectname, jsobjectvalue);"
                         `((manager ,manager)
                           (jsobjectname ,(->jstring sname))
                           (jsobjectvalue ,(->jobject vvalue))))))))
     vars))

  (let ((final-result
   (j                       
       "ourresult=null;
        try {           
           jso=manager.eval(code);
           if(jso!=null) ourresult=jso;
        } finally {
           cx.exit();
        }
        ourresult;"
       `((manager ,manager) (code ,(->jstring code))))))
    ;(d/n "final-result: " (save-to-somewhere final-result))
    final-result
    )))

(set! get-local-javascript-manager (create-thread-local-javascript-manager-retriever))

(set! js-v8
  (lambda*
   (code (vars #f) (runtime (get-local-javascript-manager)))

   (let ((vars (or vars '())))
     (each-for
      vars
      (lambda (v)
        (match-let ( ( (vname vvalue) v ) )
                   (begin
                     (let* ((sname (if (string? vname) vname (symbol->string vname)))
                            (name (->jstring sname ))
                            (code (string-append* "var " sname " = null; var fdefdeff = function(p) { " sname " = p; }; fdefdeff;"))
                            (v8f (j "v8.executeScript(script);" `((v8 ,runtime) (script ,(->jstring code)))))
                            (parameters-v8array (j "tres=new com.eclipsesource.v8.V8Array(v8runtime); tres;" `((v8runtime ,runtime)))))
                       
                       (j "v8a.push(jsobjectvalue);"
                          `((v8a ,parameters-v8array)
                            (jsobjectvalue ,(->jobject vvalue))))
                       (j "v8f.call(null, p);" `((p ,parameters-v8array) (v8f ,v8f))))))))
     
     (j "v8.executeScript(script);" `((v8 ,runtime) (script ,(->jstring code)))))))

(set! js js-v8)

