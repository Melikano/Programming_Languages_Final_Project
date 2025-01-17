;; PL Project - Fall 2018
;; NUMEX interpreter

#lang racket
(provide (all-defined-out)) ;; so we ca  n put tests in a second file

;; definition of structures for NUMEX programs

;; CHANGE add the missing ones

(struct var  (string) #:transparent)  ;; a variable, e.g., (var "foo")
(struct num  (int)    #:transparent)  ;; a constant number, e.g., (num 17)
(struct bool (b) #:transparent) ;; a constant bool
(struct plus  (e1 e2)  #:transparent)  ;; add two expressions
(struct minus  (e1 e2)  #:transparent)  ;; subtract two expressions
(struct mult  (e1 e2)  #:transparent)  ;; multiply two expressions
(struct div  (e1 e2)  #:transparent)  ;; divide two expressions
(struct neg  (e1)  #:transparent)  ;; negate an expression
(struct andalso  (e1 e2)  #:transparent)  ;; logical and two expressions
(struct orelse  (e1 e2)  #:transparent)  ;; logical or two expressions
(struct cnd  (e1 e2 e3)  #:transparent)  ;;  if then else
(struct iseq  (e1 e2)  #:transparent)  ;; compare two expressions
(struct ifnzero  (e1 e2 e3)  #:transparent)  ;; if nzero then else
(struct ifleq  (e1 e2 e3 e4)  #:transparent)  ;; if e1 > e2 then e3 else e4
(struct lam  (nameopt formal body) #:transparent) ;; a recursive(?) 1-argument function 
(struct apply (funexp actual)       #:transparent) ;; function application
(struct with  (s e1 e2)  #:transparent)  ;; let e1 be s in e2
(struct apair  (e1 e2)  #:transparent)  ;; pair e1 e2
(struct 1st  (e1)  #:transparent)  ;; first of pair e1
(struct 2nd  (e1)  #:transparent)  ;; second of pair e1
(struct munit   ()      #:transparent) ;; unit value -- good for ending a list
(struct ismunit (e1)     #:transparent) ;; if e1 is unit then true else false

;; a closure is not in "source" programs; it is what functions evaluate to
(struct closure (env f) #:transparent) 

;; Problem 1

(define (racketlist->numexlist xs)
  (cond [(null? xs) (munit)]
        [(list? xs) (apair (car xs) (racketlist->numexlist (cdr xs)))]
   ))

(define (numexlist->racketlist xs)
  (cond [(munit? xs) null]
        [(apair? xs) (cons (apair-e1 xs) (numexlist->racketlist (apair-e2 xs)))]
 ))

;; Problem 2

;; lookup a variable in an environment
;; Complete this function
(define (envlookup env str)
  (cond [(null? env) (error "unbound variable during evaluation" str)]
        [(list? env)(cond [(equal? (caar env) str) (cdr(car env))]
                          [#t(envlookup (cdr env) str)])]
))

;; Complete more cases for other kinds of NUMEX expressions.
;; We will test eval-under-env by calling it directly even though
;; "in real life" it would be a helper function of eval-exp.
(define (eval-under-env e env)
  (cond [(var? e)
          (if (string? (var-string e))
              (envlookup env (var-string e))
              (error "NUMEX var must be string"))]
        [(plus? e) 
         (let ([v1 (eval-under-env (plus-e1 e) env)]
               [v2 (eval-under-env (plus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (+ (num-int v1) 
                       (num-int v2)))
               (error "NUMEX addition applied to non-number")))]
        ;; CHANGE add more cases here

        [(num? e)
          (if (integer? (num-int e))
            (num (num-int e))
            (error "NUMEX num must be a number!"))]
        [(bool? e)
          (if (boolean? (bool-b e))
            (bool (bool-b e))
            (error "NUMEX bool must be a boolean"))]
        [(munit? e)
         (munit)]
        [(closure? e) e]
        
        [(minus? e) 
         (let ([v1 (eval-under-env (minus-e1 e) env)]
               [v2 (eval-under-env (minus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (- (num-int v1) 
                       (num-int v2)))
               (error "NUMEX subtraction applied to non-number")))]
        
        [(mult? e) 
         (let ([v1 (eval-under-env (mult-e1 e) env)]
               [v2 (eval-under-env (mult-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (* (num-int v1) 
                       (num-int v2)))
               (error "NUMEX multiplication applied to non-number")))]
        
        [(div? e) 
         (let ([v1 (eval-under-env (div-e1 e) env)]
               [v2 (eval-under-env (div-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (let ([sign (if (< (* (num-int v1) (num-int v2)) 0) -1 1)])
               (num (* sign (floor
                             (/ (abs(num-int v1)) 
                                (abs(num-int v2)))))))
               (error "NUMEX division applied to non-number")))]
        
        [(neg? e)
         (let ([v (eval-under-env (neg-e1 e) env)])

            (if (bool? v)
                (bool (not (bool-b v)))
                (if (num? v)
                    (num (- (num-int v)))
                    (error "NUMEX negartion applied to non-boolean and non-number"))))]
        
        [(andalso? e)
         (let ([v1 (eval-under-env (andalso-e1 e) env)])
           (if(bool? v1)
              (cond [(equal? (bool-b v1) #f) (bool #f)]
                    [#t (let ([v2 (eval-under-env (andalso-e2 e) env)])
                         (if (bool? v2)
                           (cond [(equal? (bool-b v2) #t) (bool #t)]
                                 [#t (bool #f)]
                            )
                           (error "NUMEX conjunction applied to non-boolean")))])
               (error "NUMEX conjunction applied to non-boolean")))] 
          
        [(orelse? e)
         (let ([v1 (eval-under-env (orelse-e1 e) env)])
            (if(bool? v1)
             (cond [(equal? (bool-b v1) #t) (bool #t)]
                   [#t (let ([v2 (eval-under-env (orelse-e2 e) env)])
                         (if (bool? v2)
                           (cond [(equal? (bool-b v2) #t) (bool #t)]
                                 [#t (bool #f)]
                            )
                         (error "NUMEX disjunction applied to non-boolean")))])
                (error "NUMEX disjunction applied to non-boolean")))] 
          
        [(cnd? e)
         (let ([v1 (eval-under-env (cnd-e1 e) env)])
           (if (bool? v1)
               (if (equal? (bool-b v1) #t)
                   (eval-under-env (cnd-e2 e) env)
                   (eval-under-env (cnd-e3 e) env))
               (error "NUMEX cnd condition is non-boolean")))]

        [(iseq? e) 
         (let ([v1 (eval-under-env (iseq-e1 e) env)]
               [v2 (eval-under-env (iseq-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (bool (equal? (num-int v1) (num-int v2)))
               (if (and(bool? v1)
                       (bool? v2))
                   (bool (equal? (bool-b v1) (bool-b v2)))
                   (bool #f))))];(error "NUMEX iseq is applied to non-number and non-boolean"))))]

        [(ifnzero? e)
         (let ([v1 (eval-under-env (ifnzero-e1 e) env)])
           (if (num? v1)
               (if (zero? (num-int v1))
                   (eval-under-env (ifnzero-e3 e) env)
                   (eval-under-env (ifnzero-e2 e) env))
               (error "NUMEX ifnzero condition is non-number")))]
        [(ifleq? e)
         (let ([v1 (eval-under-env (ifleq-e1 e) env)]
               [v2 (eval-under-env (ifleq-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (if (<= (num-int v1)
                      (num-int v2))
                   (eval-under-env (ifleq-e3 e) env)
                   (eval-under-env (ifleq-e4 e) env))
               (error "NUMEX ifnzero condition is non-number")))]
        
        [(with? e)
         (let ([e1val (eval-under-env (with-e1 e) env)])
              (eval-under-env (with-e2 e) (cons (cons (with-s e) e1val) env)))]
        
        [(lam? e)
         (closure env e)]
        
        [(apply? e)
          (let ([cl (eval-under-env (apply-funexp e) env)])
            (cond
              [(closure? cl) (let ([f (closure-f cl)])
                                       (let ([act (eval-under-env (apply-actual e) env)])
                                         (eval-under-env (lam-body f) (cons (cons (lam-formal f) act)
                                                                            (cons (cons (lam-nameopt f) cl) (closure-env cl))))))]

               [#t (error "NUMEX application of non-function")]))]

        [(apair? e)
         (let ([v1 (eval-under-env (apair-e1 e) env)]
               [v2 (eval-under-env (apair-e2 e) env)])
           (apair v1 v2))]

        [(1st? e)
          (let ([p (eval-under-env (1st-e1 e) env)])
            (if (apair? p)
                (apair-e1 p)
                (error "NUMEX 1st applied to non-pair")))]

        [(2nd? e)
          (let ([p (eval-under-env (2nd-e1 e) env)])
            (if (apair? p)
                (apair-e2 p)
                (error "NUMEX 2nd applied to non-pair")))]
        [(ismunit? e)
         (let ([m (eval-under-env (ismunit-e1 e) env)])
           (if (munit? m)
               (bool #t)
               (bool #f)))]
        
        [#t (error (format "bad NUMEX expression: ~v" e))]))


;; Do NOT change
(define (eval-exp e)
  (eval-under-env e null))
        
;; Problem 3

;(define (ifmunit e1 e2 e3)
  ;(cond [(equal? (ismunit? e1) #t) e2]
        ;[#t e3]))
(define (ifmunit e1 e2 e3)
  (cnd (ismunit e1) e2 e3))
(define (isapair e) (if (apair? e) (bool #t) (bool #f)))

(define (with* bs e2)
  (cond[(null? (cdr bs))(with (caar bs) (cdr(car bs)) e2)]
        [#t (with (caar bs) (cdr(car bs)) (with* (cdr bs) e2))]))

;(define (ifneq e1 e2 e3 e4)
  ;(cond [cnd (iseq e1 e2) e4]
        ;[#t e3]))
(define (ifneq e1 e2 e3 e4)
  (cnd (iseq e1 e2) e4 e3))

;; Problem 4

;(define numex-filter (lam "myf" "fun" (lam "f1" "list" (ifmunit (var "list") (munit) (apair (apply (var "fn") (1st (var "list")))(apply (var "f1") (2nd (var "list"))))))))
(define numex-filter (lam null "fun" (lam "f1" "list" (cnd (ismunit (var "list")) (munit)
                                                                (with "res" (apply (var "fun") (1st (var "list"))) (ifnzero (var "res") (apair (var "res") (apply (var "f1") (2nd (var "list")))) (apply (var "f1") (2nd (var "list")))))))))

(define my-numex-filter (lam null "fun" (lam "f1" "list" (cnd (ismunit (var "list")) (munit)
                                                                (with "res" (1st (var "list")) (ifnzero (var "res") (apair (apply (var "fun") (var "res")) (apply (var "f1") (2nd (var "list")))) (apply (var "f1") (2nd (var "list")))))))))



(define numex-all-gt
  (with "filter" numex-filter
        (lam null "i" (lam null "inputlist" (apply (apply (var "filter") (lam "isgt"  "x" (ifleq (var "x") (var "i") (num 0) (var "x")))) (var "inputlist"))))))

(define numex-plusone
  (with "myfilter" my-numex-filter
        (lam null "i" (lam null "inputlist" (apply (apply (var "myfilter") (lam "isgt"  "x" (plus (var "x") (num 1)))) (var "inputlist"))))))


(define isnumexlist (lam "fun" "list"  (cnd (ismunit (var "list")) (bool #t) (apply (var "fun") (2nd (var "list"))))))
;(define isnumexlist (lam "fun" "list"  (cnd (ismunit (2nd (var "list"))) (bool #t) (apply (var "fun") (2nd (var "list"))))))

;; Challenge Problem

(struct fun-challenge (nameopt formal body freevars) #:transparent) ;; a recursive(?) 1-argument function

;; We will test this function directly, so it must do
;; as described in the assignment
(define (compute-free-vars e)
   (letrec([innerfreevar(lambda (e)
                 (cond
                   [(var? e) (set (var-string e))]
                   [(num? e) (set)]
                   [(bool? e) (set)]
                   [(munit? e) (set) ]
                     
                       
                   [(apair? e)
                    (let ([v1 (innerfreevar(apair-e1 e))]
                          [v2 (innerfreevar(apair-e2 e))])
                      (set-union v1 v2))]
                   [(closure? e)
                    (closure (closure-env e) (closure-f e))]
                   [(plus? e) 
                    (let ([v1 (innerfreevar(plus-e1 e))]
                          [v2 (innerfreevar(plus-e2 e))])
                      (set-union v1 v2))]
                   [(minus? e) 
                    (let ([v1 (innerfreevar(minus-e1 e))]
                          [v2 (innerfreevar(minus-e2 e))])
                      (set-union v1 v2))]
                   [(mult? e)
                    (let ([v1 (innerfreevar(mult-e1 e))]
                          [v2 (innerfreevar(mult-e2 e))])
                      (set-union v1 v2))]
                   [(div? e)
                    (let ([v1 (innerfreevar(div-e1 e))]
                          [v2 (innerfreevar(div-e2 e))])
                      (set-union v1 v2))]
        
                   [(neg? e)
                    (let ([v1 (innerfreevar(neg-e1 e))]) v1 )]
                   
                   [(andalso? e)
                    (let ([v1 (innerfreevar(andalso-e1 e))]
                          [v2 (innerfreevar(andalso-e2 e))])
                      (set-union v1 v2))]
                   
                   [(orelse? e)
                    (let ([v1 (innerfreevar(orelse-e1 e))]
                          [v2 (innerfreevar(orelse-e2 e))])
                      (set-union v1 v2))]

                   [(iseq? e)
                    (let ([v1 (innerfreevar(iseq-e1 e))]
                          [v2 (innerfreevar(iseq-e2 e))])
                      (set-union v1 v2))]

                   [(cnd? e)
                    (let ([v1 (innerfreevar(cnd-e1 e))]
                          [v2 (innerfreevar(cnd-e2 e))]
                          [v3 (innerfreevar(cnd-e3 e))])
                      (set-union v3(set-union v1 v2)))]

                   [(ifnzero? e)
                    (let ([v1 (innerfreevar(ifnzero-e1 e))]
                          [v2 (innerfreevar(ifnzero-e2 e))]
                          [v3 (innerfreevar(ifnzero-e3 e))])
                      (set-union v3(set-union v1 v2)))]
                          
                   [(ifleq? e)
                    (let ([v1 (innerfreevar (ifleq-e1 e))]
                          [v2 (innerfreevar (ifleq-e2 e))]
                          [v3 (innerfreevar (ifleq-e3 e))]
                          [v4 (innerfreevar (ifleq-e4 e))])
                      (set-union v4(set-union v3(set-union v1 v2))))]
                   [(ismunit? e)
                    (let ([v1 (innerfreevar(ismunit-e1 e))])
                      v1)]
                              
                   [(with? e)
                    (let ([v1 (with-s e)]
                          [v2 (innerfreevar (with-e2 e))])
                      (set-remove v2 v1))]
                   [(lam? e) (let ([v1 (lam-nameopt e)]
                                   [v2 (lam-formal e)]
                                   [v3 (innerfreevar (lam-body e))])
                               (set-remove (set-remove v3 v1) v2))]
                   [(apply e) (let ([v1 (innerfreevar (apply-funexp e))]
                                    [v2 (innerfreevar (apply-actual e))])
                                (set-union v1 v2))]
                   [(1st? e) (let ([v1 (innerfreevar (1st-e1 e))])
                               v1)]
                   [(2nd? e) (let ([v1 (innerfreevar (2nd-e1 e))])
                               v1)]
                  
                   [#t (error (format "bad NUMEX expression: ~v" e))]))])
    (cond [(lam? e) (fun-challenge (lam-nameopt e) (lam-formal e) (lam-body e) (innerfreevar e))]
           [#t e])))

;; Do NOT share code with eval-under-env because that will make grading
;; more difficult, so copy most of your interpreter here and make minor changes
(define (eval-under-env-c e env)
  (cond [(var? e) 
         (envlookup env (var-string e))]
        [(plus? e) 
         (let ([v1 (eval-under-env-c(plus-e1 e) env)]
               [v2 (eval-under-env-c(plus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (+ (num-int v1) 
                       (num-int v2)))
               (error "NUMEX addition applied to non-number")))]
        ;; CHANGE add more cases here

        [(num? e)
          (if (integer? (num-int e))
            (num (num-int e))
            (error "NUMEX num must be an integer"))]
        [(bool? e)
          (if (boolean? (bool-b e))
            (bool (bool-b e))
            (error "NUMEX bool must be a boolean"))]
        [(munit? e)
         (munit)]
        [(closure? e) e]
        
        [(minus? e) 
         (let ([v1 (eval-under-env-c(minus-e1 e) env)]
               [v2 (eval-under-env-c(minus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (- (num-int v1) 
                       (num-int v2)))
               (error "NUMEX subtraction applied to non-number")))]
        
        [(mult? e) 
         (let ([v1 (eval-under-env-c(mult-e1 e) env)]
               [v2 (eval-under-env-c(mult-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (* (num-int v1) 
                       (num-int v2)))
               (error "NUMEX multiplication applied to non-number")))]
        
        [(div? e) 
         (let ([v1 (eval-under-env-c (div-e1 e) env)]
               [v2 (eval-under-env-c (div-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (let ([sign (if (< (* (num-int v1) (num-int v2)) 0) -1 1)])
               (num (* sign (floor
                             (/ (abs(num-int v1)) 
                                (abs(num-int v2)))))))
               (error "NUMEX division applied to non-number")))]
        
        [(neg? e)
         (let ([v (eval-under-env-c(neg-e1 e) env)])

            (if (bool? v)
                (bool (not (bool-b v)))
                (if (num? v)
                    (num (- (num-int v)))
                    (error "NUMEX negartion applied to non-boolean and non-number"))))]
        
        [(andalso? e)
         (let ([v1 (eval-under-env-c(andalso-e1 e) env)])
           (if(bool? v1)
              (cond [(equal? (bool-b v1) #f) (bool #f)]
                    [#t (let ([v2 (eval-under-env-c(andalso-e2 e) env)])
                         (if (bool? v2)
                           (cond [(equal? (bool-b v2) #t) (bool #t)]
                                 [#t (bool #f)]
                            )
                           (error "NUMEX conjunction applied to non-boolean")))])
               (error "NUMEX conjunction applied to non-boolean")))] 
          
        [(orelse? e)
         (let ([v1 (eval-under-env-c(orelse-e1 e) env)])
            (if(bool? v1)
             (cond [(equal? (bool-b v1) #t) (bool #t)]
                   [#t (let ([v2 (eval-under-env-c(orelse-e2 e) env)])
                         (if (bool? v2)
                           (cond [(equal? (bool-b v2) #t) (bool #t)]
                                 [#t (bool #f)]
                            )
                         (error "NUMEX disjunction applied to non-boolean")))])
                (error "NUMEX disjunction applied to non-boolean")))] 
          
        [(cnd? e)
         (let ([v1 (eval-under-env-c(cnd-e1 e) env)])
           (if (bool? v1)
               (if (equal? (bool-b v1) #t)
                   (eval-under-env-c(cnd-e2 e) env)
                   (eval-under-env-c(cnd-e3 e) env))
               (error "NUMEX cnd condition is non-boolean")))]

        [(iseq? e) 
         (let ([v1 (eval-under-env-c(iseq-e1 e) env)]
               [v2 (eval-under-env-c(iseq-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (bool (equal? (num-int v1) (num-int v2)))
               (if (and(bool? v1)
                       (bool? v2))
                   (bool (equal? (bool-b v1) (bool-b v2)))
                   (bool #f))))];(error "NUMEX iseq is applied to non-number and non-boolean"))))]

        [(ifnzero? e)
         (let ([v1 (eval-under-env-c(ifnzero-e1 e) env)])
           (if (num? v1)
               (if (zero? (num-int v1))
                   (eval-under-env-c(cnd-e3 e) env)
                   (eval-under-env-c(cnd-e2 e) env))
               (error "NUMEX ifnzero condition is non-number")))]
        [(ifleq? e)
         (let ([v1 (eval-under-env-c(ifleq-e1 e) env)]
               [v2 (eval-under-env-c(ifleq-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (if (<= (num-int v1)
                      (num-int v2))
                   (eval-under-env-c(ifleq-e3 e) env)
                   (eval-under-env-c(ifleq-e4 e) env))
               (error "NUMEX ifnzero condition is non-number")))]
        
        [(with? e)
         (let ([e1val (eval-under-env-c(with-e1 e) env)])
              (eval-under-env-c(with-e2 e) (cons (cons (with-s e) e1val)  env)))]
        [(lam? e)
         (eval-under-env-c(compute-free-vars e) env)]
        
        [(fun-challenge? e)
         (letrec([filterenv(lambda (e1)
                      (if (null? e1)
                          e1
                          (if (set-member? (fun-challenge-freevars e) (caar e1))
                              (cons (car e1) (filterenv (cdr e1)))
                              (filterenv (cdr e1)))
                          ))])
           (closure (filterenv env) e))]
        
        [(apply? e)
          (let ([cl (eval-under-env-c(apply-funexp e) env)])
            (cond
              [(closure? cl) (let ([f (closure-f cl)])
                               (let ([act (eval-under-env-c(apply-actual e) env)])
                                         (eval-under-env-c(lam-body f) (cons (cons (lam-formal f) act)
                                                                              (cons (cons (lam-nameopt f) cl) (closure-env cl))))))]

               [#t (error "NUMEX application of non-function")]))]

        [(apair? e)
         (let ([v1 (eval-under-env-c(apair-e1 e) env)]
               [v2 (eval-under-env-c(apair-e2 e) env)])
           (apair v1 v2))]

        [(1st? e)
          (let ([p (eval-under-env-c(1st-e1 e) env)])
            (if (apair? p)
                (apair-e1 p)
                (error "NUMEX 1st applied to non-pair")))]

        [(2nd? e)
          (let ([p (eval-under-env-c(2nd-e1 e) env)])
            (if (apair? p)
                (apair-e2 p)
                (error "NUMEX 2nd applied to non-pair")))]
        [(ismunit? e)
         (let ([m (eval-under-env-c(ismunit-e1 e) env)])
           (if (munit? m)
               (bool #t)
               (bool #f)))]
        
        [#t (error (format "bad NUMEX expression: ~v" e))]))


;; Do NOT change this
(define (eval-exp-c e)
  (eval-under-env-c (compute-free-vars e) null))
