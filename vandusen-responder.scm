(module
  vandusen-responder (responder)

  (import chicken scheme)
  (use vandusen irc posix srfi-1 srfi-13 regex data-structures)

  ($ 'responder-prefix "!")

  (define responders '())

  (define (responder key action)
    (debug (conc "Adding responder " key))
    (set! responders (alist-cons key action responders)))

  (define (run-responder m cmd data sender receiver)
    (and-let* ((responder (assoc cmd responders))
               (action (cdr responder))
               (result (action cmd sender receiver data)))
              (debug (conc cmd " action result: " result))
              (reply-to m result prefixed: #f)))

  (plugin 'responder
          (lambda ()
            (message-handler
              (lambda (m)
                (and-let* ((body (cadr (irc:message-parameters m)))
                           (matches (string-match (conc ($ 'responder-prefix) "(\\S+)\\s*(.*)") body)))
                          (debug (conc "Running responder " (cadr matches)))
                          (run-responder m
                                         (string->symbol (cadr matches))
                                         (string-trim-both (caddr matches))
                                         (string-trim-both (irc:message-sender m))
                                         (string-trim-both (irc:message-receiver m))))
                #f)
              command: "PRIVMSG"))))
