(use gauche.test)
(use srfi-13)
(test-start "bcrypt")

(use crypt.bcrypt)
(test-module 'crypt.bcrypt)

;; Test data is taken from wrapper.c
(define (test-hashpw hash pw)
  (test* "bcrypt-hashpw" hash (bcrypt-hashpw pw hash)))

(test-hashpw "$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW"
             "U*U")
(test-hashpw "$2a$05$CCCCCCCCCCCCCCCCCCCCC.VGOzA784oUp/Z0DY336zx7pLYAy0lwK"
             "U*U*")
(test-hashpw "$2a$05$XXXXXXXXXXXXXXXXXXXXXOAcXxm9kjPGEMsLznoKqmqw7tc8WCx4a"
             "U*U*U")
(test-hashpw "$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui"
             "0123456789abcdefghijklmnopqrstuvwxyz\
              ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
(test-hashpw "$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui"
	     "0123456789abcdefghijklmnopqrstuvwxyz\
	      ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\
	      chars after 72 are ignored")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"
	     #*"\xa3;")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"
	     #*"\xff;\xff;\xa3;")
(test-hashpw "$2y$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"
	     #*"\xff;\xff;\xa3;")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nqd1wy.pTMdcvrRWxyiGL2eMz.2a85."
	     #*"\xff;\xff;\xa3;")
(test-hashpw "$2b$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"
	     #*"\xff;\xff;\xa3;")
(test-hashpw "$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"
	     #*"\xa3;")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"
	     #*"\xa3;")
(test-hashpw "$2b$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"
	     #*"\xa3;")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"
	     #*"1\xa3;345")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"
	     #*"\xff;\xa3;345")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"
	     #*"\xff;\xa3;34\xff;\xff;\xff;\xa3;345")
(test-hashpw "$2y$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"
	     #*"\xff;\xa3;34\xff;\xff;\xff;\xa3;345")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.ZC1JEJ8Z4gPfpe1JOr/oyPXTWl9EFd."
	     #*"\xff;\xa3;34\xff;\xff;\xff;\xa3;345")
(test-hashpw "$2y$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"
	     #*"\xff;\xa3;345")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"
	     #*"\xff;\xa3;345")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"
	     #*"\xa3;ab")
(test-hashpw "$2x$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"
	     #*"\xa3;ab")
(test-hashpw "$2y$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"
	     #*"\xa3;ab")
(test-hashpw "$2x$05$6bNw2HLQYeqHYyBfLMsv/OiwqTymGIGzFsA4hOTWebfehXHNprcAS"
	     #*"\xd1;\x91;")
(test-hashpw "$2x$05$6bNw2HLQYeqHYyBfLMsv/O9LIGgn8OMzuDoHfof8AQimSGfcSWxnS"
	     #*"\xd0;\xc1;\xd2;\xcf;\xcc;\xd8;")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.swQOIzjOiJ9GHEPuhEkvqrUyvWhEMx6"
	     #*"\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        \xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        \xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        \xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        \xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        \xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\xaa;\
	        chars after 72 are ignored as usual")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.R9xrDjiycxMbQE2bp.vgqlYpW5wx2yy"
	     #*"\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\
	        \xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\
	        \xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\
	        \xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\
	        \xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\
	        \xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;\xaa;\x55;")
(test-hashpw "$2a$05$/OK.fbVrR/bpIqNJ5ianF.9tQZzcJfm3uj2NvJ/n5xkhpqLrMpWCe"
	     #*"\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\
	        \x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\
	        \x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\
	        \x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\
	        \x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\
	        \x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;\x55;\xaa;\xff;")
(test-hashpw "$2a$05$CCCCCCCCCCCCCCCCCCCCC.7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy"
	     "")

(test* "bcrypt-gensalt" "$2a$12$"
       (string-take (bcrypt-gensalt :count 12) 7))

(test-end)
