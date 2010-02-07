;;; The contents of this file are subject to the Mozilla Public License Version
;;; 1.1 (the "License"); you may not use this file except in compliance with
;;; the License. You may obtain a copy of the License at
;;; http://www.mozilla.org/MPL/
;;;
;;; Software distributed under the License is distributed on an "AS IS" basis,
;;; WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
;;; for the specific language governing rights and limitations under the
;;; License.
;;;
;;; The Original Code is SISCweb.
;;;
;;; The Initial Developer of the Original Code is Alessandro Colomba.
;;; Portions created by the Initial Developer are Copyright (C) 2005
;;; Alessandro Colomba. All Rights Reserved.
;;;
;;; Contributor(s):
;;;
;;; Alternatively, the contents of this file may be used under the terms of
;;; either the GNU General Public License Version 2 or later (the "GPL"), or
;;; the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
;;; in which case the provisions of the GPL or the LGPL are applicable instead
;;; of those above. If you wish to allow use of your version of this file only
;;; under the terms of either the GPL or the LGPL, and not to allow others to
;;; use your version of this file under the terms of the MPL, indicate your
;;; decision by deleting the provisions above and replace them with the notice
;;; and other provisions required by the GPL or the LGPL. If you do not delete
;;; the provisions above, a recipient may use your version of this file under
;;; the terms of any one of the MPL, the GPL or the LGPL.


(require-library 'sisc/libs/srfi/srfi-42) ; eager comprehensions
(require-library 'sisc/libs/srfi/srfi-45) ; primitives for expressing iterative lazy algorithms

(require-library 'sql/type-conversion)


(module sql/result-set
  (make-rs-accessor get-column-names
   rs/map rs/for-each)

  (import s2j)
  (import hashtable)

  (import srfi-42)
  (import srfi-45)

  (import sql/type-conversion)

  (define-generic-java-methods get-column-count get-column-name get-column-type get-column-type-name get-meta-data get-object get-scale next prepare-statement to-lower-case was-null)


  (define (get-column-names-as-symbols rs)
    (define md (get-meta-data rs))

    (list-ec (:range i 1 (+ 1 (->number (get-column-count md))))
      (->symbol (to-lower-case (get-column-name md (->jint i))))))

  (define (get-column-names rs)
    (define md (get-meta-data rs))

    (list-ec (:range i 1 (+ 1 (->number (get-column-count md))))
      (->string (get-column-name md (->jint i)))))


  (define (make-rs-accessor rs vendor)
    (define md (get-meta-data rs))

    (define (make-field-accessor convert-proc ji)
      (lambda ()
        (let ((obj (get-object rs ji)))
          (if (->boolean (was-null rs))
              '()
              (convert-proc obj md ji)))))


    (define (make-accessor-table)
      (let* ((n (->number (get-column-count md)))
             (at (make-hashtable string=? #f)))
        (do-ec (:range i 1 (+ 1 n))
          (let* ((ji (->jint i))
                 (name
                  ;(->symbol
                  ; (to-lower-case
                  (->string
                    (get-column-name md ji)
                    )
                  ;  )
                  ; )                  
                       )
                 (type (get-column-type md ji))
                 (sql->scheme (get-sql->scheme-proc type vendor)))
            (hashtable/put! at name (make-field-accessor sql->scheme ji))))
        at))

    (let ((at (make-accessor-table)))
      (lambda (symbol)
        ((hashtable/get at symbol)))))


  (define (rs/map proc resultset)
    (define (M rs)
      (if (null? (force rs))
          '()
          (cons (proc (car (force rs)))
                (M (cdr (force rs))))))

    (M resultset))


  (define (rs/for-each proc resultset)
    (let loop ((rs resultset))
      (when (not (null? (force rs)))
        (proc (car (force rs)))
        (loop (cdr (force rs))))))


  )
