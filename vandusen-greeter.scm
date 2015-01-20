(module
  vandusen-greeter ()

  (import chicken scheme)
  (use vandusen irc data-structures extras srfi-18)

  (define (greetings) (or ($ 'greetings) '("hello")))

  (define (random-greet) (list-ref (greetings) (random (length (greetings)))))

  (plugin 'greeter
          (lambda ()
            (message-handler
              (lambda (m)
                (thread-start!
                  (lambda ()
                    (thread-sleep! 5)
                    (let ((sender (irc:message-sender m)))
                      (debug (conc "Saying hello to " sender))
                      (if (string=? ($ 'nick) sender)
                        (reply-to m (conc (random-greet) " everybody!") prefixed: #f)
                        (reply-to m (conc (random-greet) " " sender) prefixed: #f)))))
                #f)
              command: "JOIN"))))
