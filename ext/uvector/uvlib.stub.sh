cat << EOF
;;;
;;; uvlib.stub - uniform vector library
;;;
;;;   Copyright (c) 2000-2002 Shiro Kawai (shiro@acm.org)
;;;
;;;   Permission to use, copy, modify, distribute this software and
;;;   accompanying documentation for any purpose is hereby granted,
;;;   provided that existing copyright notices are retained in all
;;;   copies and that this notice is included verbatim in all
;;;   distributions.
;;;   This software is provided as is, without express or implied
;;;   warranty.  In no circumstances the author(s) shall be liable
;;;   for any damages arising out of the use of this software.
;;;
;;; \$Id: uvlib.stub.sh,v 1.9 2002-06-19 08:18:23 shirok Exp $
;;;

"
#include \\"gauche/uvector.h\\"
#include \\"uvectorP.h\\"
"

(define-symbol both "sym_both")
(define-symbol high "sym_high")
(define-symbol low  "sym_low")

"static int clamp_arg(ScmObj clamp)
 {
   if (SCM_EQ(clamp, sym_both)) return SCM_UVECTOR_CLAMP_BOTH;
   else if (SCM_EQ(clamp, sym_low))  return SCM_UVECTOR_CLAMP_LO;
   else if (SCM_EQ(clamp, sym_high)) return SCM_UVECTOR_CLAMP_HI;
   if (!SCM_FALSEP(clamp) && !SCM_UNBOUNDP(clamp))
     Scm_Error(\"clamp argument must be either 'both, 'high, 'low or #f, but got %S\", clamp);
   return SCM_UVECTOR_CLAMP_NONE;
 }
"
EOF

emit() {
    vecttag=$1
    VECTTAG=`echo $vecttag | tr '[a-z]' '[A-Z]'`
    vecttype="${VECTTAG}Vector"
    itemtype="${VECTTAG}ELTTYPE"
    integer=$4
    VECTTYPE="${VECTTAG}VECTOR"
    cat <<EOF
;;--------------------------------------------------------------------
;; $vecttype
;;
(define-type "${vecttag}vector" ${vecttag}vector?
  "Scm${vecttype}*" "SCM_${VECTTYPE}P" "SCM_${VECTTYPE}")

(define-cproc ${vecttag}vector? (obj)
  "SCM_RETURN(SCM_MAKE_BOOL(SCM_${VECTTYPE}P(obj)));")

(define-cproc make-${vecttag}vector (length &optional (fill 0))
  (assert (small-integer? length))
  "  ${itemtype} filler;
  ${VECTTAG}UNBOX(filler, fill, 0);
  SCM_RETURN(Scm_Make${vecttype}(length, filler));")

(define-cproc ${vecttag}vector (&rest args)
  "  SCM_RETURN(Scm_ListTo${vecttype}(args, 0));")

(define-cproc ${vecttag}vector-length (v)
  (assert (${vecttag}vector? v))
  "  SCM_RETURN(SCM_MAKE_INT(SCM_${VECTTYPE}_SIZE(v)));")

(define-cproc ${vecttag}vector-ref (v i &optional fallback)
  (assert (${vecttag}vector? v))
  (assert (small-integer? i))
  (setter ${vecttag}vector-set!)
  "  SCM_RETURN(Scm_${vecttype}Ref(v, i, fallback));")

(define-cproc ${vecttag}vector-set! (v i val &optional clamp)
  (assert (${vecttag}vector? v))
  (assert (small-integer? i))
  "  SCM_RETURN(Scm_${vecttype}Set(v, i, val, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-copy (v &optional (start 0) (end -1))
  (assert (${vecttag}vector? v))
  (assert (${vecttag}vector? v))
  (assert (small-integer? start))
  (assert (small-integer? end))
  "  SCM_RETURN(Scm_${vecttype}Copy(v, start, end));")

(define-cproc ${vecttag}vector-copy! (dst src)
  (assert (${vecttag}vector? dst))
  (assert (${vecttag}vector? src))
  "  SCM_RETURN(Scm_${vecttype}CopyX(dst, src));")

(define-cproc ${vecttag}vector->list (v &optional (start 0) (end -1))
  (assert (${vecttag}vector? v))
  (assert (small-integer? start))
  (assert (small-integer? end))
  "  SCM_RETURN(Scm_${vecttype}ToList(v, start, end));")

(define-cproc list->${vecttag}vector (l &optional clamp)
  (assert (list? l))
  "  SCM_RETURN(Scm_ListTo${vecttype}(l, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-fill! (v val &optional (start 0) (end -1))
  (assert (${vecttag}vector? v))
  (assert (small-integer? start))
  (assert (small-integer? end))
  "  ${itemtype} filler;
  ${VECTTAG}UNBOX(filler, val, 0);
  SCM_RETURN(Scm_${vecttype}Fill(v, filler, start, end));")

(define-cproc ${vecttag}vector->vector (v &optional (start 0) (end -1))
  (assert (${vecttag}vector? v))
  (assert (small-integer? start))
  (assert (small-integer? end))
  "  SCM_RETURN(Scm_${vecttype}ToVector(v, start, end));")

(define-cproc vector->${vecttag}vector (v &optional (start 0) (end -1) clamp)
  (assert (vector? v))
  (assert (small-integer? start))
  (assert (small-integer? end))
  "  SCM_RETURN(Scm_VectorTo${vecttype}(v, start, end, clamp_arg(clamp)));")

; Arithmetic operations
;(define-cproc ${vecttag}vector-add! (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  "SCM_RETURN(Scm_${vecttype}Add(v0, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-add (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
;  SCM_RETURN(Scm_${vecttype}Add(dst, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-sub! (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  "SCM_RETURN(Scm_${vecttype}Sub(v0, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-sub (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
;  SCM_RETURN(Scm_${vecttype}Sub(dst, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-mul! (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  "SCM_RETURN(Scm_${vecttype}Mul(v0, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-mul (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
;  SCM_RETURN(Scm_${vecttype}Mul(dst, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-div! (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  "SCM_RETURN(Scm_${vecttype}Div(v0, v0, v1, clamp_arg(clamp)));")

;(define-cproc ${vecttag}vector-div (v0 v1 &optional clamp)
;  (assert (${vecttag}vector? v0))
;  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
;  SCM_RETURN(Scm_${vecttype}Div(dst, v0, v1, clamp_arg(clamp)));")

EOF

    if [ "$integer" = 1 ]; then
    cat <<EOF
(define-cproc ${vecttag}vector-mod! (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  "SCM_RETURN(Scm_${vecttype}Mod(v0, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-mod (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
  SCM_RETURN(Scm_${vecttype}Mod(dst, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-and! (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  "SCM_RETURN(Scm_${vecttype}And(v0, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-and (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
  SCM_RETURN(Scm_${vecttype}And(dst, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-ior! (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  "SCM_RETURN(Scm_${vecttype}Ior(v0, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-ior (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
  SCM_RETURN(Scm_${vecttype}Ior(dst, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-xor! (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  "SCM_RETURN(Scm_${vecttype}Xor(v0, v0, v1, clamp_arg(clamp)));")

(define-cproc ${vecttag}vector-xor (v0 v1 &optional clamp)
  (assert (${vecttag}vector? v0))
  " Scm${vecttype} *dst = SCM_${VECTTYPE}(Scm_Make${vecttype}(SCM_${VECTTYPE}_SIZE(v0), 0));
  SCM_RETURN(Scm_${vecttype}Xor(dst, v0, v1, clamp_arg(clamp)));")
EOF
    fi
}

emit s8  S8Vector  "char" 0
emit u8  U8Vector  "unsigned char" 0
emit s16 S16Vector "short" 0
emit u16 U16Vector "unsigned short" 0
emit s32 S32Vector SCM_UVECTOR_INT32 0
emit u32 U32Vector SCM_UVECTOR_UINT32 0
emit s64 S64Vector SCM_UVECTOR_INT64 0
emit u64 U64Vector SCM_UVECTOR_UINT64 0
emit f32 F32Vector "float"
emit f64 F64Vector "double"

