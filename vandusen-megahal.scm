(module
  vandusen-megahal ()

  (import chicken scheme foreign)
  (use vandusen irc regex data-structures srfi-13 srfi-18 extras posix)

  (define megahal-setnobanner (foreign-lambda void "megahal_setnobanner"))
  (define megahal-setnoprompt (foreign-lambda void "megahal_setnoprompt"))
  (define megahal-initialize (foreign-lambda void "megahal_initialize"))
  (define megahal-do-reply (foreign-lambda c-string "megahal_do_reply" c-string))
  (define megahal-cleanup (foreign-lambda void "megahal_cleanup"))

  (define (initialize) 
    (megahal-setnobanner)
    (megahal-setnoprompt)
    (megahal-initialize))

  ; Get the body from the message object
  (define (message-body m)
    (cadr (irc:message-parameters m)))

  ; String any nicks from the beginning of the text
  (define (cleanup text)
    (string-downcase (string-substitute "^\\S+:\\s+" "" text)))

  ; Truncate to 128 chars max, with ellipsis if required
  (define (trunc text)
    (if (> (string-length text) 128)
      (conc (string-take text 124) " ...")
      text))

  ; Try and get a reply and, if we are mentioned, return it
  (define (get-reply text)
    (let ((reply (megahal-do-reply (cleanup text))))
      (if (string-search ($ 'nick) text)
        (trunc reply)
        #f)))

  ; Handle a message and send any reply after a random delay
  (define (handle-message m)
    (and-let* ((body (message-body m))
               (reply (get-reply body)))
              (thread-start!
                (lambda ()
                  (thread-sleep! (+ 1 (random 4)))
                  (reply-to m reply prefixed: #t)))))

  ; MegaHAL plugin for chatterbot functionality
  (plugin 'megahal
          (lambda ()

            ; Save the brain
            (command 'save-brain
                     `(: "save-brain")
                     (lambda (m)
                       (debug "saving brain")
                       (megahal-cleanup)
                       (initialize))
                     public: #t)

            ; Handle any message that starts with a reference to us that
            ; hasn't been picked up by anyone else
            (command 'fall-through
                     '(* any)
                     (lambda (m) (handle-message m))
                     public: #t)

            ; Handle any message that doesn't start with a reference to us
            (message-handler
              (lambda (m)
                (let ((body (message-body m)))
                  (if (not (string-search (conc "^" ($ 'nick) ":") body))
                    (handle-message m)))
                #f)
              command: "PRIVMSG")

            ; Clean up at the end
            (add-finalizer (lambda ()
                             (debug "saving brain")
                             (set-signal-handler! signal/alrm #f)
                             (megahal-cleanup)))

            ; Initialize for the first time
            (initialize)

            ; Install a periodic handler to save the brain
            (set-signal-handler! signal/alrm
                                 (lambda (n)
                                   (debug "periodic saving brain")
                                   (megahal-cleanup)
                                   (initialize)))

            ; Every hour by default
            (set-alarm! (or ($ 'megahal-save-timeout) 3600))
            (debug (conc "saving brain every " (or ($ 'megahal-save-timeout) 3600) "seconds")))))
