;;; perlrefactor.el --- minor mode for Perl::Critic integration

;;; Readme
;;
;; This is a minor mode for emacs intended to allow you to
;; automatically incorporate perlrefactor into your daily code
;; writing. When enabled it can optionally prevent you from saving
;; code that doesn't pass your enabled perlrefactor policies.
;;
;; Even if you don't enable the automatic code checking you can still
;; use the automatic checking or the `perlrefactor' function.


;;; Installation instructions:
;;
;;   Copy perlrefactor.el to your ~/.site-lib directory. If you don't
;;   have a .site-lib directory create it and add the following line
;;   to your .emacs file. This location isn't special, you could use
;;   a different location if you wished.
;;
;;     (add-to-list 'load-path "/home/your-name/.site-lisp")
;;
;;   Add the following lines to your .emacs file. This allows Emacs
;;   to load your perlrefactor library only when needed.
;;
;;     (autoload 'perlrefactor        "perlrefactor" "" t)
;;     (autoload 'perlrefactor-region "perlrefactor" "" t)
;;     (autoload 'perlrefactor-mode   "perlrefactor" "" t)
;;
;;   Add the following to your .emacs file to get perlrefactor-mode to
;;   run automatically for the `cperl-mode' and `perl-mode'.
;;
;;     (eval-after-load "cperl-mode"
;;      '(add-hook 'cperl-mode-hook 'perlrefactor-mode))
;;     (eval-after-load "perl-mode"
;;      '(add-hook 'perl-mode-hook 'perlrefactor-mode))
;;
;;
;;   If you think you need perlrefactor loaded all the time you can
;;   make this unconditional by using the following command instead
;;   of the above autoloading.
;;
;;     (require 'perlrefactor)
;;
;;   Compile the file for extra performance. This is optional. You
;;   will have to redo this everytime you modify or upgrade your
;;   perlrefactor.el file.
;;
;;     M-x byte-compile-file ~/.site-lib/perlrefactor.el
;;
;;   Additional customization can be found in the Perl::Critic group
;;   in the Tools section in the Programming section of your Emacs'
;;   customization menus.


;;;   TODO
;;
;;     Find out how to get perlrefactor customization stuff into the
;;     customization menus without having to load perlrefactor.el
;;     first.
;;
;;     This needs an installer. Is there anything I can use in
;;     ExtUtils::MakeMaker, Module::Build, or Module::Install?
;;     Alien::?
;;
;;     XEmacs compatibility. I use GNU Emacs and don't test in
;;     XEmacs. I'm happy to do what it takes to be compatible but
;;     someone will have to point things out to me.
;;
;;     Make all documentation strings start with a sentence that fits
;;     on one line. See "Tips for Documentation Strings" in the Emacs
;;     Lisp manual.
;;
;;     Any FIXME, TODO, or XXX tags below.


;;; Change Log:
;; 0.10
;;   * Synched up regexp alist with Perl::Critic::Utils and accounted for all
;;     past patterns too.
;; 0.09
;;   * Added documentation for perlrefactor-top, perlrefactor-include,
;;     perlrefactor-exclude, perlrefactor-force, perlrefactor-verbose.
;;   * Added emacs/vim editor hints to the bottom.
;;   * Corrected indentation.
;; 0.08
;;   * Fixed perlrefactor-compilation-error-regexp-alist for all
;;     severity levels.
;;   * Added documentation strings for functions.
;; 0.07
;;   * Moved perlrefactor-compilation-error-regexp-alist so it is in the
;;     source before it's used. This only seems to matter when
;;     perlrefactor.el is compiled to bytecode.
;;   * Added perlrefactor-exclude, perlrefactor-include

;; 0.06
;;   * Code cleanliness.
;;   * Comment cleanliness.
;;   * Nice error message when perlrefactor warns.
;;   * Documented perlrefactor-top, perlrefactor-verbose.
;;   * Regular expressions for the other standard -verbose levels.
;;   * Reversed Changes list so the most recent is first.
;;   * Standard emacs library declarations.
;;   * Added autoloading metadata.
;; 0.05
;;   * perlrefactor-bin invocation now shown in output.
;;   * Fixed indentation.
;;   * perlrefactor-region is now interactive.
;; 0.04
;;   * Removed a roque file-level (setq perlrefactor-top 1)
;;   * Moved cl library to compile-time.
;; 0.03
;;   * compile.el integration. This makes for hotlink happiness.
;;   * Better sanity when starting the *perlrefactor* buffer.
;; 0.02
;;   * perlrefactor-severity-level added.
;;   * Touched up the installation documentation.
;;   * perlrefactor-pass-required is now buffer local.
;; 0.01
;;   * It's new. I copied much of this from perl-lint-mode.

;;; Copyright and license
;;
;;   2006 Joshua ben Jore <jjore@cpan.org>
;;
;;   This program is free software; you can redistribute it and/or
;;   modify it under the same terms as Perl itself




;;; Code:

;;; Customization and variables.
(defgroup perlrefactor nil "Perl::Critic"
  :prefix "perlrefactor-"
  :group 'tools)

(defcustom perlrefactor-bin "perlrefactor"
  "The perlrefactor program used by `perlrefactor'."
  :type 'string
  :group 'perlrefactor)

(defcustom perlrefactor-pass-required nil
  "When \\[perlrefactor-mode] is enabled then this boolean controls
whether your file can be saved when there are perlrefactor warnings.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio
	  (const :tag "Require no warnings from perlrefactor to save" t)
	  (const :tag "Allow warnings from perlrefactor when saving" nil))
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-pass-required)

(defcustom perlrefactor-profile nil
  "Specify an alternate .perlrefactorrc file. This is only used if
non-nil."
  :type '(string)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-profile)

(defcustom perlrefactor-noprofile nil
  "Disables the use of any .perlrefactorrc file."
  :type '(boolean)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-noprofile)

(defcustom perlrefactor-severity nil
  "Directs perlrefactor to only report violations of Enforcers with a
severity greater than N. Severity values are integers ranging from
1 (least severe) to 5 (most severe). The default is 5. For a given
-profile, decreasing the -severity will usually produce more
violations.  Users can redefine the severity for any Enforcer in their
.perlrefactorrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio
	  (const :tag "Show only the most severe: 5" 5)
	  (const :tag "4" 4)
	  (const :tag "3" 3)
	  (const :tag "2" 2)
	  (const :tag "Show everything including the least severe: 1" 1)
	  (const :tag "Default from .perlrefactorrc" nil))
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-severity)

(defcustom perlrefactor-top nil
  "Directs \"perlrefactor\" to report only the top N Enforcer violations in
each file, ranked by their severity. If the -severity option is not
explicitly given, the -top option implies that the minimum severity
level is 1. Users can redefine the severity for any Enforcer in their
.perlrefactorrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(integer)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-top)

(defcustom perlrefactor-include nil
  "Directs \"perlrefactor\" to apply additional Enforcers that match the regex \"/PATTERN/imx\".
Use this option to override your profile and/or the severity settings.

For example:

  layout

This would cause \"perlrefactor\" to apply all the \"CodeLayout::*\" policies
even if they have a severity level that is less than the default level of 5,
or have been disabled in your .perlrefactorrc file.  You can specify multiple
`perlrefactor-include' options and you can use it in conjunction with the
`perlrefactor-exclude' option.  Note that `perlrefactor-exclude' takes precedence
over `perlrefactor-include' when a Enforcer matches both patterns.  You can set
the default value for this option in your .perlrefactorrc file."
  :type '(string)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-include)

(defcustom perlrefactor-exclude nil
  "Directs \"perlrefactor\" to not apply any Enforcer that matches the regex
\"/PATTERN/imx\".  Use this option to temporarily override your profile and/or
the severity settings at the command-line.  For example:

  strict

This would cause \"perlrefactor\" to not apply the \"RequireUseStrict\" and
\"ProhibitNoStrict\" Enforcers even though they have the highest severity
level.  You can specify multiple `perlrefactor-exclude' options and you can use
it in conjunction with the `perlrefactor-include' option.  Note that
`perlrefactor-exclude' takes precedence over `perlrefactor-include' when a Enforcer
matches both patterns.  You can set the default value for this option in your
.perlrefactorrc file."
  :type '(string)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-exclude)


(defcustom perlrefactor-force nil
  "Directs \"perlrefactor\" to ignore the magical \"## no critic\"
pseudo-pragmas in the source code. You can set the default value for this
option in your .perlrefactorrc file."
  :type '(boolean)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-force)

(defcustom perlrefactor-verbose nil
  "Sets the numeric verbosity level or format for reporting violations. If
given a number (\"N\"), \"perlrefactor\" reports violations using one of the
predefined formats described below. If the `perlrefactor-verbose' option is not
specified, it defaults to either 4 or 5, depending on whether multiple files
were given as arguments to \"perlrefactor\".  You can set the default value for
this option in your .perlrefactorrc file.

Verbosity     Format Specification
-----------   -------------------------------------------------------------
 1            \"%f:%l:%c:%m\n\",
 2            \"%f: (%l:%c) %m\n\",
 3            \"%m at %f line %l\n\",
 4            \"%m at line %l, column %c.  %e.  (Severity: %s)\n\",
 5            \"%f: %m at line %l, column %c.  %e.  (Severity: %s)\n\",
 6            \"%m at line %l, near ’%r’.  (Severity: %s)\n\",
 7            \"%f: %m at line %l near ’%r’.  (Severity: %s)\n\",
 8            \"[%p] %m at line %l, column %c.  (Severity: %s)\n\",
 9            \"[%p] %m at line %l, near ’%r’.  (Severity: %s)\n\",
10            \"%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n\",
11            \"%m at line %l, near ’%r’.\n  %p (Severity: %s)\n%d\n\"

Formats are a combination of literal and escape characters similar to the way
\"sprintf\" works.  See String::Format for a full explanation of the
formatting capabilities.  Valid escape characters are:

Escape    Meaning
-------   ----------------------------------------------------------------
%c        Column number where the violation occurred
%d        Full diagnostic discussion of the violation
%e        Explanation of violation or page numbers in PBP
%F        Just the name of the file where the violation occurred.
%f        Path to the file where the violation occurred.
%l        Line number where the violation occurred
%m        Brief description of the violation
%P        Full name of the Enforcer module that created the violation
%p        Name of the Enforcer without the Perl::Critic::Enforcer:: prefix
%r        The string of source code that caused the violation
%s        The severity level of the violation

The purpose of these formats is to provide some compatibility with text
editors that have an interface for parsing certain kinds of input.


This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(integer)
  :group 'perlrefactor)
(make-variable-buffer-local 'perlrefactor-verbose)

;; TODO: Enable strings in perlrefactor-verbose.
;; (defcustom perlrefactor-verbose-regexp nil
;;   "An optional  regexp to match the warning output.
;;
;; This is used when `perlrefactor-verbose' has a regexp instead of one of
;; the standard verbose levels.")
;; (make-local-variable 'perlrefactor-verbose-regexp)


;; compile.el requires that something be the "filename." I've tagged
;; the severity with that. It happens to make it get highlighted in
;; red. The following advice on COMPILATION-FIND-FILE makes sure that
;; the "filename" is getting ignored when perlrefactor is using it.

;; These patterns are defined in Perl::Critic::Utils

(defvar perlrefactor-error-error-regexp-alist nil
  "Alist that specified how to match errors in perlrefactor output.")
(setq perlrefactor-error-error-regexp-alist
      '(;; Verbose level 1
        ;;  "%f:%l:%c:%m\n"
        ("^\\([^\n]+\\):\\([0-9]+\\):\\([0-9]+\\)" 1 2 3 1)

        ;; Verbose level 2
        ;;  "%f: (%l:%c) %m\n"
        ("^\\([^\n]+\\): (\\([0-9]+\\):\\([0-9]+\\))" 1 2 3 1)

        ;; Verbose level 3
        ;;   "%m at %f line %l\n"
        ("^[^\n]+ at \\([^\n]+\\) line \\([0-9]+\\)" 1 2 nil 1)
        ;;   "%m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)." nil 2 3 1)

        ;; Verbose level 4
        ;;   "%m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^[^\n]+\\( \\)at line \\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;   "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\)" 1 2 3)

        ;; Verbose level 5
        ;;    "%m at line %l, near '%r'.  (Severity: %s)\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)," nil 2)
        ;;    "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\)" 1 2 3)

        ;; Verbose level 6
        ;;    "%m at line %l, near '%r'.  (Severity: %s)\\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ;;    "%f: %m at line %l near '%r'.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\)" 1 2)

        ;; Verbose level 7
        ;;    "%f: %m at line %l near '%r'.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\)" 1 2)
        ;;    "[%p] %m at line %l, column %c.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)

        ;; Verbose level 8
        ;;    "[%p] %m at line %l, column %c.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;    "[%p] %m at line %l, near '%r'.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)

        ;; Verbose level 9
        ;;    "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;    "[%p] %m at line %l, near '%r'.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)

        ;; Verbose level 10
        ;;    "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ;;    "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)

        ;; Verbose level 11
        ;;    "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ))



;; The Emacs Lisp manual says to do this with the cl library.
(eval-when-compile (require 'cl))

(define-compilation-mode perlrefactor-error-mode "perlrefactor-error"
  "..."
  (set (make-local-variable 'perlrefactor-buffer) src-buf)
  (ad-activate #'compilation-find-file))

;;;###autoload
(defun perlrefactor ()
  "\\[perlrefactor]] returns a either nil or t depending on whether the
current buffer passes perlrefactor's check. If there are any warnings
those are displayed in a separate buffer."
  (interactive)
  (save-restriction
    (widen)
    (perlrefactor-region (point-min) (point-max))))

;;;###autoload
(defun perlrefactor-region (start end)
  "\\[perlrefactor-region] returns a either nil or t depending on
whether the region passes perlrefactor's check. If there are any
warnings those are displayed in a separate buffer."

  (interactive "r")

  ;; Kill the perlrefactor buffer so I can make a new one.
  (if (get-buffer "*perlrefactor*")
      (kill-buffer "*perlrefactor*"))

  ;; In the following lines I'll be switching between buffers
  ;; freely. This upper save-excursion will keep things sane.
  (save-excursion
    (let ((src-buf (current-buffer))
          (err-buf (get-buffer-create "*perlrefactor*")))

      (set-buffer src-buf)
      (let ((perlrefactor-args (loop for p in (list
                                             ;; Add new bin/perlrefactor
                                             ;; parameters here!
					     (perlrefactor--param-profile)
					     (perlrefactor--param-noprofile)
                                             (perlrefactor--param-severity)
                                             (perlrefactor--param-top)
					     (perlrefactor--param-include)
					     (perlrefactor--param-exclude)
					     (perlrefactor--param-force)
                                             (perlrefactor--param-verbose))
                                   unless (null p)
                                   append p)))
                                        ;
        (message "Perl critic...running")
        ;; Seriously. Is this the nicest way to call
        ;; CALL-PROCESS-REGION with variadic arguments? This blows!
        ;; (apply FUNCTION (append STATIC-PART DYNAMIC-PART))
        (let ((rc (apply 'call-process-region
                         (nconc (list start end
                                      perlrefactor-bin nil
                                      (list err-buf t)
                                      nil)
                                perlrefactor-args))))

          ;; Figure out whether we're ok or not. perlrefactor has to
          ;; return zero and the output buffer has to be empty except
          ;; for that "... source OK" line. Different versions of the
          ;; perlrefactor script will print different things when
          ;; they're ok. I expect to see things like "some-file source
          ;; OK", "SCALAR=(0x123457) source OK", "STDIN source OK",
          ;; and "source OK".
          (let ((perlrefactor-ok (and (numberp rc)
                                    (zerop rc)
                                    (progn
				      (set-buffer err-buf)
				      (goto-char (point-min))
				      (delete-matching-lines "source OK$")
				      (zerop (buffer-size))))))
            ;; Either clean up or finish setting up my output.
            (if perlrefactor-ok
		;; Ok!
                (progn
                  (kill-buffer err-buf)
                  (message "Perl critic...ok"))


	      ;; Not ok!
	      (message "Perl critic...not ok")

              ;; Set up the output buffer now I know it'll be used.  I
              ;; scooped the guts out of compile-internal. It is
              ;; CRITICAL that the errors start at least two lines
              ;; from the top. compile.el normally assumes the first
              ;; line is an informational `cd somedirectory' command
              ;; and the second line shows the program's invocation.
	      ;;
	      ;; Since I have the space available I've put the
	      ;; program's invocation here. Maybe it'd make sense to
	      ;; put the buffer's directory here somewhere too.
              (set-buffer err-buf)
              (goto-char (point-min))
              (insert (reduce (lambda (a b) (concat a " " b))
                              (nconc (list perlrefactor-bin)
                                     perlrefactor-args))
                      "\n"
		      ;; TODO: instead of a blank line, print the
		      ;; buffer's directory+file.
		      "\n")
              (goto-char (point-min))
	      ;; TODO: get `recompile' to work.

	      ;; just an fyi. compilation-mode will delete my local
	      ;; variables so be sure to call it *first*.
              (perlrefactor-error-mode)
              ;; (ad-deactivate #'compilation-find-file)
              (display-buffer err-buf))

	    ;; Return our success or failure.
            perlrefactor-ok))))))




;;; Parameters for use by perlrefactor-region.
(defun perlrefactor--param-profile ()
  "A private method that supplies the -profile FILENAME parameter for
\\[perlrefactor-region]"
  (if perlrefactor-profile (list "-profile" perlrefactor-profile)))

(defun perlrefactor--param-noprofile ()
  "A private method that supplies the -noprofile parameter for
\\[perlrefactor-region]"
  (if perlrefactor-noprofile (list "-noprofile")))

(defun perlrefactor--param-force ()
  "A private method that supplies the -force parameter for
\\[perlrefactor-region]"
  (if perlrefactor-force (list "-force")))

(defun perlrefactor--param-severity ()
  "A private method that supplies the -severity NUMBER parameter for
\\[perlrefactor-region]"
  (cond ((stringp perlrefactor-severity)
	 (list "-severity" perlrefactor-severity))
        ((numberp perlrefactor-severity)
	 (list "-severity" (number-to-string perlrefactor-severity)))
        (t nil)))

(defun perlrefactor--param-top ()
  "A private method that supplies the -top NUMBER parameter for
\\[perlrefactor-region]"
  (cond ((stringp perlrefactor-top)
	 (list "-top" perlrefactor-top))
        ((numberp perlrefactor-top)
	 (list "-top" (number-to-string perlrefactor-top)))
        (t nil)))

(defun perlrefactor--param-include ()
  "A private method that supplies the -include REGEXP parameter for
\\[perlrefactor-region]"
  (if perlrefactor-include
      (list "-include" perlrefactor-include)
    nil))

(defun perlrefactor--param-exclude ()
  "A private method that supplies the -exclude REGEXP parameter for
\\[perlrefactor-region]"
  (if perlrefactor-exclude
      (list "-exclude" perlrefactor-exclude)
    nil))

(defun perlrefactor--param-verbose ()
  "A private method that supplies the -verbose NUMBER parameter for
\\[perlrefactor-region]"
  (cond ((stringp perlrefactor-verbose)
	 (list "-verbose" perlrefactor-verbose))
        ((numberp perlrefactor-verbose)
	 (list "-verbose" (number-to-string perlrefactor-verbose)))
        (t nil)))


;; Interactive functions for use by the user to modify parameters on
;; an adhoc basis. I'm sure there's room for significant niceness
;; here. Suggest something. Please.
(defun perlrefactor-profile (profile)
  "Sets perlrefactor's -profile FILENAME parameter."
  (interactive "sperlrefactor -profile: ")
  (setq perlrefactor-profile (if (string= profile "") nil profile)))

(defun perlrefactor-noprofile (noprofile)
  "Toggles perlrefactor's -noprofile parameter."
  (interactive (list (yes-or-no-p "Enable perlrefactor -noprofile? ")))
  (setq perlrefactor-noprofile noprofile))

(defun perlrefactor-force (force)
  "Toggles perlrefactor's -force parameter."
  (interactive (list (yes-or-no-p "Enable perlrefactor -force? ")))
  (setq perlrefactor-force force))

(defun perlrefactor-severity (severity)
  "Sets perlrefactor's -severity NUMBER parameter."
  (interactive "nperlrefactor -severity: ")
  (setq perlrefactor-severity severity))

(defun perlrefactor-top (top)
  "Sets perlrefactor's -top NUMBER parameter."
  (interactive "nperlrefactor -top: ")
  (setq perlrefactor-top top))

(defun perlrefactor-include (include)
  "Sets perlrefactor's -include REGEXP parameter."
  (interactive "sperlrefactor -include: ")
  (setq perlrefactor-include include))

(defun perlrefactor-exclude (exclude)
  "Sets perlrefactor's -exclude REGEXP parameter."
  (interactive "sperlrefactor -exclude: ")
  (setq perlrefactor-exclude exclude))

(defun perlrefactor-verbose (verbose)
  "Sets perlrefactor's -verbose NUMBER parameter."
  (interactive "nperlrefactor -verbose: ")
  (setq perlrefactor-verbose verbose))





;; Hooks compile.el's compilation-find-file to enable our file-less
;; operation. We feed `perlrefactor-bin' from STDIN, not from a file.
(defadvice compilation-find-file (around perlrefactor-find-file)
  "Lets perlrefactor lookup into the buffer we just came from and don't
require that the perl document exist in a file anywhere."
  (let ((debug-buffer (marker-buffer marker)))
    (if (local-variable-p 'perlrefactor-buffer debug-buffer)
        (setq ad-return-value perlrefactor-buffer)
      ad-do-it)))





;; All the scaffolding of having a minor mode.
(defvar perlrefactor-mode nil
  "Toggle `perlrefactor-mode'")
(make-variable-buffer-local 'perlrefactor-mode)

(defun perlrefactor-write-hook ()
  "Check perlrefactor during `write-file-hooks' for `perlrefactor-mode'"
  (if perlrefactor-mode
      (save-excursion
        (widen)
        (mark-whole-buffer)
        (let ((perlrefactor-ok (perlrefactor)))
          (if perlrefactor-pass-required
	      ;; Impede saving if we're not ok.
              (not perlrefactor-ok)
	    ;; Don't impede saving. We might not be ok but that
	    ;; doesn't matter now.
            nil)))
    ;; Don't impede saving. We're not in perlrefactor-mode.
    nil))

;;;###autoload
(defun perlrefactor-mode (&optional arg)
  "Perl::Critic checking minor mode."
  (interactive "P")

  ;; Enable/disable perlrefactor-mode
  (setq perlrefactor-mode (if (null arg)
			    ;; Nothing! Just toggle it.
			    (not perlrefactor-mode)
			  ;; Set it.
			  (> (prefix-numeric-value arg) 0)))

  (make-local-hook 'write-file-hooks)
  (if perlrefactor-mode
      (add-hook 'write-file-hooks 'perlrefactor-write-hook)
    (remove-hook 'write-file-hooks 'perlrefactor-write-hook)))

;; Make a nice name for perl critic mode. This string will appear at
;; the bottom of the screen.
(if (not (assq 'perlrefactor-mode minor-mode-alist))
    (setq minor-mode-alist
          (cons '(perlrefactor-mode " Critic")
                minor-mode-alist)))

(provide 'perlrefactor)

;; Local Variables:
;; mode: emacs-lisp
;; tab-width: 8
;; fill-column: 78
;; indent-tabs-mode: nil
;; End:
;; ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

;;; perlrefactor.el ends here
