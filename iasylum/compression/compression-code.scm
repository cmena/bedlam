(define (lzw-compress value)
  (let ((result (->string (j "com.diogoduailibe.lzstring4j.LZString.compressToUTF16(v);" `((v ,(->jstring value)))))))
    (log-trace 'lzw-compress (format "Compression ratio: ~0,2F%" (* 100 (/ (string-length result)
                                                                           (string-length value)))))
    result))

(define (lzw-decompress value)
  (let ((result (->string (j "com.diogoduailibe.lzstring4j.LZString.decompressFromUTF16(v);" `((v ,(->jstring value)))))))
    (log-trace 'lzw-decompress (format "Decompression ratio: ~0,2F%" (* 100 (/ (string-length result)
                                                                               (string-length value)))))
    result))


;; Sample roundtrip working:
;;(js "iasylum.compression.lzw_decompress(nv);" `((nv ,(->string (j "com.diogoduailibe.lzstring4j.LZString.compress(v);" `((v ,(->jstring (->string (js "iasylum.compression.lzw_decompress(v);" `((v ,(->string (j "com.diogoduailibe.lzstring4j.LZString.compress(v);" `((v ,(->jstring "aline")))))))))))))))))


;;(->string
;; (j "com.diogoduailibe.lzstring4j.LZString.decompressFromBase64(v);"
;;    `((v ,(js "LZString.compressToBase64(v);"
;;              `((v ,(->jstring (->string (js "LZString.decompressFromBase64(v);"
;;                                             `((v ,(->string
;;                                                    (j "com.diogoduailibe.lzstring4j.LZString.compressToBase64(v);"
;;                                                       `((v ,(->jstring "aline")))))))))))))))))
