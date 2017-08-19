;;;
;;; srfi-132 - sort library
;;;

;; This is a thin adaptor for Gauche's built-in sort procedures.

(define-module srfi-132
  (use gauche.sequence)
  (use gauche.generator)
  (use srfi-27)   ; we use random selection in vector-select
  (use srfi-133)
  (export list-sorted? vector-sorted?
          list-sort list-stable-sort
          list-sort! list-stable-sort!
          vector-sort vector-stable-sort
          vector-sort! vector-stable-sort!
          list-merge list-merge!
          vector-merge vector-merge!
          list-delete-neighbor-dups
          list-delete-neighbor-dups!
          vector-delete-neighbor-dups
          vector-delete-neighbor-dups!
          vector-find-median
          ;; vector-find-median!
          vector-select!
          ;; vector-separate!
          ))
(select-module srfi-132)

(define (list-sort < lis) (assume-type lis <list>) (sort lis <))
(define (list-sort! < lis) (assume-type lis <list>) (sort! lis <))
(define (list-stable-sort < lis) (assume-type lis <list>) (stable-sort lis <))
(define (list-stable-sort! < lis) (assume-type lis <list>) (stable-sort! lis <))
(define (list-sorted? < lis) (assume-type lis <list>) (sorted? lis <))
(define (list-merge < lis1 lis2) (merge lis1 lis2 <))
(define (list-merge! < lis1 lis2) (merge! lis1 lis2 <))

;; NB: We could get range-restricted linear-update version more efficient.

(define-inline (%check-range v start end)
  (assume-type start <integer>)
  (assume-type end <integer>)
  (unless (<= 0 start end (vector-length v))
    (errorf "Start/end arguments must be nonnegative exact integers, \
             and must be (<= 0 start end (- (vector-length v) 1)). \
             We got (start end): (~s ~s)" start end)))

(define (%vector-sorter %sort!)
  (^[< v :optional (s 0) (e (vector-length v))]
    (assume-type v <vector>)
    (%check-range v s e)
    (let1 sorted (%sort! (subseq v s e) <)
      (if (and (= s 0) (= e (vector-length v)))
        sorted
        (vector-append (subseq v 0 s) sorted (subseq v e (vector-length v)))))))

(define (%vector-sorter! %sort!)
  (^[< v :optional (s 0) (e (vector-length v))]
    (assume-type v <vector>)
    (%check-range v s e)
    (if (and (= s 0) (= e (vector-length v)))
      (%sort! v <)
      (begin
        (set! (subseq v s e) (%sort! (subseq v s e) <))
        v))))

(define vector-sort (%vector-sorter sort!))
(define vector-sort! (%vector-sorter! sort!))
(define vector-stable-sort (%vector-sorter stable-sort!))
(define vector-stable-sort! (%vector-sorter! stable-sort!))

(define (%maybe-subseq v s e)
  (if (and (= s 0) (= e (vector-length v)))
    v
    (subseq v s e)))

(define (vector-sorted? < v :optional (s 0) (e (vector-length v)))
  (assume-type v <vector>)
  (%check-range v s e)
  (sorted? (%maybe-subseq v s e) <))

(define (%vector-merge! < dst start v1 v2)
  (let ([len1 (vector-length v1)]
        [len2 (vector-length v2)])
    (cond [(zero? len1) (vector-copy! dst start v2)]
          [(zero? len2) (vector-copy! dst start v1)]
          [else (let loop ([e1 (vector-ref v1 0)]
                           [e2 (vector-ref v2 0)]
                           [i1 1]
                           [i2 1]
                           [d start])
                  (cond [(< e2 e1)
                         (vector-set! dst d e2)
                         (if (= i2 len2)
                           (vector-copy! dst (+ d 1) v1 (- i1 1))
                           (loop e1 (vector-ref v2 i2) i1 (+ i2 1) (+ d 1)))]
                        [else
                         (vector-set! dst d e1)
                         (if (= i1 len1)
                           (vector-copy! dst (+ d 1) v2 (- i2 1))
                           (loop (vector-ref v1 i1) e2 (+ i1 1) i2 (+ d 1)))]))]
          )))

(define (vector-merge < v1 v2 :optional (s1 0) (e1 (vector-length v1))
                                        (s2 0) (e2 (vector-length v2)))
  (assume-type v1 <vector>)
  (assume-type v2 <vector>)
  (%check-range v1 s1 e1)
  (%check-range v2 s2 e2)
  (rlet1 vr (make-vector (+ (- e1 s1) (- e2 s2)))
    (%vector-merge! < vr 0 (%maybe-subseq v1 s1 e1) (%maybe-subseq v2 s2 e2))))

(define (vector-merge! < vr v1 v2 :optional (sr 0)
                                            (s1 0) (e1 (vector-length v1))
                                            (s2 0) (e2 (vector-length v2)))
  (assume-type vr <vector>)
  (assume-type v1 <vector>)
  (assume-type v2 <vector>)
  (%check-range v1 s1 e1)
  (%check-range v2 s2 e2)
  (unless (>= (vector-length vr) (+ sr (- e1 s1) (- e2 s2)))
    (errorf "Destination vector is too short (length=~s, required=~s)"
            (vector-length vr) (+ sr (- e1 s1) (- e2 s2))))
  (%vector-merge! < vr sr (%maybe-subseq v1 s1 e1) (%maybe-subseq v2 s2 e2))
  vr)

;; duplicate elimination

(define (list-delete-neighbor-dups = lis)
  (assume-type lis <list>)
  (delete-neighbor-dups lis :test =))
(define (list-delete-neighbor-dups! = lis)
  (assume-type lis <list>)
  (delete-neighbor-dups-squeeze! lis :test =))
(define (vector-delete-neighbor-dups = vec :optional (start 0) (end #f))
  (assume-type vec <vector>)
  (delete-neighbor-dups vec :test = :start start :end end))
(define (vector-delete-neighbor-dups! = vec :optional (start 0) (end #f))
  (assume-type vec <vector>)
  (delete-neighbor-dups! vec :test = :start start :end end))

;;;
;;; Median finding / k-th largest element
;;;

(define (vector-select! elt< v k :optional (start 0) (end (vector-length v)))
  (assume-type v <vector>)
  (assume-type k <integer>)
  (assume (<= start k (- end 1) (- (vector-length v) 1)))
  (vector-select-1! elt< v k start end))

(define (vector-find-median elt< v knil :optional (mean (^[a b] (/ (+ a b) 2))))
  (assume-type v <vector>)
  (case (vector-length v)
    [(0) knil]
    [(1) (vector-ref v 0)]
    [(2) (mean (vector-ref v 0) (vector-ref v 1))]
    [else
     => (^[len]
          (if (odd? len)
            (vector-select-1! elt< (vector-copy v) (ash len -1) 0 len)
            (receive (a b) (vector-select-2! elt< (vector-copy v)
                                             (- (ash len -1) 1) 0 len)
              (mean a b))))]))

;; We use our own random-source to avoid unexpected interference
(define *random-source*
  (rlet1 r (make-random-source)
    (random-source-randomize! r)))

;; Rearrange elements of VEC between start and end, so that all elements
;; smaller than the pivot are gathered at the front, followed
;; by elements greater than the pivot.
;;
;;  #(G S P G S G G P S S)   ; S:smaller, P:pivot, G:greater
;;
;;  to:
;;            a       b
;;  #(S S S S G G G G X X)   ; X: don't care 
;;
;; Returns a and b.
;;
;; In the implementation, we use typical two-index scan, where i moves from
;; start to right, while j moves from the end to left.  Elements
;; equal to pivot are removed, which is done by shrinking the region
;; with moving end to left.
;;
;; Invariances:
;;   vec[start] .. vec[i-1] are always smaller than the pivot
;;   vec[k] .. vec[end-1]   are always greater than the pivot
;;   start <= i <= k <= end
;;   vec[end-1] is not equal to pivot (we make it so at the beginning)
;;
;;    i                   j E
;;  #(S G S P G S P G S P G)     ; forward
;;      i                 j E
;;  #(S G S P G S P G S P G)     ; backward
;;      i               j   E
;;  #(S G S P G S P G S P G)     ; shrink v[j] = v[E-1]
;;      i               j E
;;  #(S G S P G S P G S G _)     ; backward
;;      i             j   E
;;  #(S G S P G S P G S G _)     ; swap  v[i] <=> v[j]
;;      i             j   E
;;  #(S S S P G S P G G G _)     ; forward
;;        i           j   E
;;  #(S S S P G S P G G G _)     ; forward
;;          i         j   E
;;  #(S S S P G S P G G G _)     ; forward
;;          i         j   E
;;  #(S S S P G S P G G G _)     ; shrink v[i] = v[E-1]
;;          i         j E
;;  #(S S S G G S P G G _ _)     ; backward
;;          i       j   E
;;  #(S S S G G S P G G _ _)     ; backward
;;          i     j     E
;;  #(S S S G G S P G G _ _)     ; shrink v[j] = v[E-1]
;;          i     j   E
;;  #(S S S G G S G G _ _ _)     ; backward
;;          i   j     E
;;  #(S S S G G S G G _ _ _)     ; swap  v[i] <=> v[j]
;;          i   j     E
;;  #(S S S S G G G G _ _ _)     ; forward
;;            i j     E
;;  #(S S S S G G G G _ _ _)     ; backward
;;            ij      E
;;  #(S S S S G G G G _ _ _)     ; end

(define (partition-in-place! elt< pivot vec start end)
  (define (forward i j end)
    (cond [(> i j) (values i end)]
          [(elt< (vector-ref vec i) pivot) (forward (+ i 1) j end)]
          [(elt< pivot (vector-ref vec i)) (backward i j end)]
          [else                         ;shrink
           (vector-set! vec i (vector-ref vec (- end 1))) ; now v[i] > pivot
           (if (= j (- end 1))
             (adjust i (- j 1))
             (backward i j (- end 1)))]))
  (define (backward i j end)  ; v[i] > pivot
    (cond [(>= i j) (values i end)]
          [(elt< (vector-ref vec j) pivot)
           (vector-swap! vec i j)
           (forward (+ i 1) (- j 1) end)]
          [(elt< pivot (vector-ref vec j)) (backward i (- j 1) end)]
          [else ; shrink
           (vector-set! vec j (vector-ref vec (- end 1)))
           (backward i j (- end 1))]))
  (define (adjust i end-1) ; keep invariance of v[end-1] > pivot.  v[i] > pivot
    (cond [(> i end-1) (values i i)]
          [(elt< pivot (vector-ref vec end-1))
           (backward i end-1 (+ end-1 1))]
          [(elt< (vector-ref vec end-1) pivot)
           (vector-swap! vec i end-1)
           (forward i end-1 (+ end-1 1))]
          [else (adjust i (- end-1 1))]))
  ;; We first scan from the end to satisfy the condition that v[end-1] > pivot.
  (let init ([m (- end 1)])
    (cond [(> start m) (values start start)]
          [(elt< pivot (vector-ref vec m))
           (forward start m (+ m 1))]
          [(elt< (vector-ref vec m) pivot)
           ;; We should find at least one element greater than pivot.
           ;; Scanning vector back, keeping the invariance that
           ;; elements not equal to the pivot is contained between [start,m]
           (let init2 ([m m]
                       [n (- m 1)])
             (cond [(> start n) (values (+ m 1) (+ m 1))]
                   [(elt< pivot (vector-ref vec n))
                    (vector-swap! vec n m)
                    (forward start m (+ m 1))]
                   [(elt< (vector-ref vec n) pivot)
                    (init2 m (- n 1))]
                   [else
                    (vector-set! vec n (vector-ref vec m))
                    (init2 (- m 1) (- n 1))]))]
          [else (init (- m 1))])))

(define (vector-select-1! elt< vec k start end)
  (let loop ([k k] [start start] [end end])
    (define size (- end start))
    (case size
      [(1) (vector-ref vec start)] ; k must be 0
      [(2) (let ([a (vector-ref vec start)]
                 [b (vector-ref vec (+ start 1))])
             (if (elt< a b)
               (if (zero? k) a b)
               (if (zero? k) b a)))]
      [else
       (let* ([ip (random-integer size)]
              [pivot (vector-ref vec (+ ip start))])
         (receive (i j) (partition-in-place! elt< pivot vec start end)
           (let1 nsmaller (- i start)
             (if (< k nsmaller)
               (loop k start i)
               (let1 nsmaller-or-equal (+ nsmaller (- end j))
                 (if (< k nsmaller-or-equal)
                   pivot
                   (loop (- k nsmaller-or-equal) i j)))))))])))

;; precondition: (- end start) >= 2
(define (vector-select-2! elt< vec k start end)
  (let loop ([k k] [start start] [end end])
    (define size (- end start))
    (if (= size 2)
      (let ([a (vector-ref vec start)]
            [b (vector-ref vec (+ start 1))])
        (if (elt< a b) (values a b) (values b a)))
      (let* ([ip (random-integer size)]
             [pivot (vector-ref vec (+ ip start))])
        (receive (i j) (partition-in-place! elt< pivot vec start end)
          (let1 nsmaller (- i start)
            (cond [(= (+ k 1) nsmaller)
                   (values (vector-select-1! elt< vec k start i) pivot)]
                  [(< k nsmaller) (loop k start i)]
                  [else
                   (let1 nsmaller-or-equal (+ nsmaller (- end j))
                     (cond [(= (+ k 1) nsmaller-or-equal)
                            (values pivot (vector-select-1! elt< vec 0 i j))]
                           [(< k nsmaller-or-equal)
                            (values pivot pivot)]
                           [else (loop (- k nsmaller-or-equal) i j)]))])))))))


