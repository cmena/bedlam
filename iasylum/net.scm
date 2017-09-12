(require-extension (lib iasylum/jcode))

(module iasylum/net
  (http-call-get/string
   http-call-get-headers/string 
   http-call-post-string/string
   )

  ; (http-call-get/string "http://news.ycombinator.com") retrieves those page contents as a string.
  (define (http-call-get/string destinationUrl)
    (->string
     (j "httpclient = org.apache.http.impl.client.HttpClients.createDefault();
        httpget = new org.apache.http.client.methods.HttpGet(destinationurl);
        response = httpclient.execute(httpget);
        result=\"\";
        try {
          tent=response.getEntity();
          result=org.apache.http.util.EntityUtils.toString(tent);
        } catch(Exception e) {
          throw new RuntimeException(e);
        } finally {
          response.close();
        }

        result;"
        `((httpclient)(httpget)(response)(result)
          (destinationurl ,(->jstring destinationUrl))))))


  ;; Implements headers to GET requests
  (define http-call-get-headers/string 
    (lambda* (destinationUrl (headers: headers #f))
             (let ((httpclient (j "httpclient = org.apache.http.impl.client.HttpClients.createDefault();"
                               `((httpclient))))
                   (httpget (j "httpget = new org.apache.http.client.methods.HttpGet(destinationurl);
                                httpget;"
                               `((httpget)
                                 (destinationurl ,(->jstring destinationUrl))))))

               (map (lambda (v)  (match-let ( ( (vname vvalue) v ) )
                                   (j "httpget.addHeader(hn, hv);"`((hn ,(->jstring vname)) (hv ,(->jstring vvalue)) (httpget ,httpget)))
                                   )) headers)
               
               (j "response = httpclient.execute(httpget);
      result=\"\";
      try {
        tent=response.getEntity();
        result=org.apache.http.util.EntityUtils.toString(tent);
      } catch(Exception e) {
        throw new RuntimeException(e);
      } finally {
        response.close();
      }

      result;"
                  `((response)(result)(tent)(httpget ,httpget)(httpclient ,httpclient))))))
  
  ;; TODO file upload - http://stackoverflow.com/questions/1067655/how-to-upload-a-file-using-java-httpclient-library-working-with-php
  (define http-call-post-string/string
    (lambda* (destinationUrl contents (headers: headers #f))
             (let ((httpclient (j "httpclient = org.apache.http.impl.client.HttpClients.createDefault();" `((httpclient))))
                   (httppost (j "httppost = new org.apache.http.client.methods.HttpPost(destinationurl);
                                 httppost;"
                                `((httppost)(destinationurl ,(->jstring destinationUrl))))))
               
               (map (lambda (v)  (match-let ( ( (vname vvalue) v ) )
                                            (j "httppost.addHeader(hn, hv);"`((hn ,(->jstring vname)) (hv ,(->jstring vvalue)) (httppost ,httppost)))
                                            )) headers)
                                              
             (->string
               (j "httppost.setEntity(new org.apache.http.entity.StringEntity(contents));
                  response = httpclient.execute(httppost);
                  result=\"\";
                  try {
                    tent=response.getEntity();
                    result=org.apache.http.util.EntityUtils.toString(tent);
                  } catch(Exception e) {
                    throw new RuntimeException(e);
                  } finally {
                    response.close();
                  }
          
                  result;"
                  `((response)(result)(tent)
                    (contents ,(->jstring contents))
                    (httppost ,httppost)
                    (httpclient ,httpclient)))))))

)
