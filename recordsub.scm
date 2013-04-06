(load "lib.scm")

(define typ
  (lambda (ty)
    (conde
      ((== 'top ty))
      ((== 'bot ty))
      ((fresh (ty1 ty2)
         (== `(arr ,ty1 ,ty2) ty)
         (typ ty1)
         (typ ty2)))
      ((fresh (r)
         (== `(rcd ,r) ty)
         (typ-rcd r))))))

(define f-rcd
  (lambda (f r)
    (conde
      ((== r ∅))
      ((fresh (l ft rr)
         (== r (set rr `(,l ,ft)))
         (label-!ino l rr)
         (symbolo l)
         (f ft)
         (f-rcd f rr))))))

(define typ-rcd
  (lambda (r) (f-rcd typ r)))

(define label-!ino
  (lambda (l r)
    (conde
      ((== r ∅))
      ((fresh (ol oty rr)
         (== r (set rr `(,ol ,oty)))
         (!ino `(,ol ,oty) rr)
         (=/= ol l)
         (label-!ino l rr))))))

'(
   (run 100 (q) (typ-rcd q))
 )

(define labelso
  (lambda (r ls)
    (conde
      ((== r ∅) (== ls ∅))
      ((fresh (l ty rr lsr)
         (== r (set rr `(,l ,ty)))
         (== ls (set lsr l))
         (!ino `(,l ,ty) rr)
         (!ino l lsr)
         (labelso rr lsr))))))

(define sub
  (lambda (ty1 ty2)
    (conde
      ((== ty1 ty2)
       ;;;(typ ty1)
       )
      ((=/= ty1 ty2)
       (conde
         ((== 'top ty2)
          ;;;(typ ty1)
         )
         ((== 'bot ty1)
          ;;;(typ ty2)
         )
         ((fresh (tya1 tyb1 tya2 tyb2)
            (== `(arr ,tya1 ,tyb1) ty1)
            (== `(arr ,tya2 ,tyb2) ty2)
            (sub tya2 tya1)
            (sub tyb1 tyb2)))
         ((fresh (r1 r2)
            (== `(rcd ,r1) ty1)
            (== `(rcd ,r2) ty2)
            (sub-rcd r1 r2))))))))

(define sub-rcd
  (lambda (r1 r2)
    (fresh (ls1 ls2)
      (subseto ls2 ls1)
      (labelso r1 ls1)
      (labelso r2 ls2)
      (conde
        ((== r2 ∅)
         ;;;(typ-rcd r1)
         )
        ((fresh (l ty1 rr1 ty2 rr2)
           (== r1 (set rr1 `(,l ,ty1)))
           (== r2 (set rr2 `(,l ,ty2)))
           (symbolo l)
           (sub ty1 ty2)
           (label-!ino l rr1)
           (label-!ino l rr2)
           (sub-rcd rr1 rr2)))))))

'(
   (run 10 (q)
     (fresh (ty1 ty2)
       (=/= ty1 ty2)
       (=/= ty2 `(rcd ,∅))
       (== q `(,ty1 ,ty2))
       (sub ty1 ty2)))
 )

(define exp
  (lambda (e bvars)
    (conde
      ((symbolo e)
       (ino e bvars))
      ((fresh (x body)
         (symbolo x)
         (== `(lambda (,x) ,body) e)
         (exp body (set bvars x))))
      ((fresh (r)
         (== `(new ,r) e)
         (exp-rcd r bvars)))
      ((fresh (e1 e2)
         (== `(app ,e1 ,e2) e)
         (exp e1 bvars)
         (exp e2 bvars))))))

(define exp-rcd
  (lambda (r bvars) (f-rcd (lambda (e) (exp e bvars)) r)))

'(
   (run 100 (q) (exp-rcd q ∅))
 )

(define bound-vars-ofo labelso)

(define bound-ino
  (lambda (x env)
    (fresh (bvars)
      (bound-vars-ofo env bvars)
      (ino x bvars))))

(define !bound-ino
  (lambda (x env)
    (fresh (bvars)
      (bound-vars-ofo env bvars)
      (!ino x bvars))))

(define lookupo
  (lambda (x env ty)
    (fresh (y v rest)
      (== env (set rest `(,y ,v)))
      (!ino `(,y ,v) rest)
      (conde
        ((== y x) (== v ty))
        ((=/= y x)
         (lookupo x rest ty))))))

(define tc
  (lambda (e env ty)
    (conde
      ((symbolo e)
       (lookupo e env ty))
      ((fresh (x body ty-x ty-body ty-body-actual)
         (== `(lambda (,x) ,body) e)
         (== `(arr ,ty-x ,ty-body) ty)
         (symbolo x)
         (!bound-ino 'lambda env)
         (tc body (set env `(,x ,ty-x)) ty-body)))
      ((fresh (rator ty-param rand ty-rand)
         (== `(app ,rator ,rand) e)
         (!bound-ino 'app env)
         (tc rator env `(arr ,ty-param ,ty))
         (tc rand env ty-rand)
         (sub ty-rand ty-param)))
      ((fresh (re rt)
         (== `(new ,re) e)
         (!bound-ino 'new env)
         (== `(rcd ,rt) ty)
         (tc-rcd re env rt))))))

(define tc-rcd
  (lambda (re env rt)
    (conde
      ((== re ∅)
       (== rt ∅))
      ((fresh (l e ty rre rrt)
         (== re (set rre `(,l ,e)))
         (== rt (set rrt `(,l ,ty)))
         (!ino `(,l ,e) rre)
         (!ino `(,l ,ty) rrt)
         (tc e env ty)
         (tc-rcd rre env rrt))))))

'(
   (run 100 (q) (fresh (e ty) (== q `(,e ,ty)) (tc e ∅ ty)))
   (run 10 (q) (fresh (re rt) (== q `(,re ,rt)) (tc-rcd re ∅ rt)))
 )
