
;; Copyright (C) 2010  David O'Toole

;; Author: David O'Toole <dto@gnu.org>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
(defpackage :void
  (:use :xe2 :common-lisp)
  (:export physics))

(in-package :void)
(defparameter *timestep* 20)
(defparameter *grid-size* 16)
(defparameter *width* 1280)
(defparameter *height* 720)
(defvar *form*)
(defvar *pager*)
(defvar *narrator*)
(defvar *prompt*)
(defvar *player*)
(defvar *status*)
(defvar *viewport*)
(defparameter *numpad-keybindings* 
  '(("KP8" nil "move :north .")
    ("KP4" nil "move :west .")
    ("KP6" nil "move :east .")
    ("KP2" nil "move :south .")
    ;; 
    ("UP" nil "move :north .")
    ("LEFT" nil "move :west .")
    ("RIGHT" nil "move :east .")
    ("DOWN" nil "move :south .")
    ;; 
    ("KP8" (:shift) "move :north .")
    ("KP4" (:shift) "move :west .")
    ("KP6" (:shift) "move :east .")
    ("KP2" (:shift) "move :south .")
    ;; 
    ("UP" (:shift) "move :north .")
    ("LEFT" (:shift) "move :west .")
    ("RIGHT" (:shift) "move :east .")
    ("DOWN" (:shift) "move :south .")))

(defparameter *qwerty-keybindings*
  (append *numpad-keybindings*
          '(("K" nil "move :north .")
            ("H" nil "move :west .")
            ("L" nil "move :east .")
            ("J" nil "move :south .")
            ;;
            ("K" (:shift) "move :north .")
            ("H" (:shift) "move :west .")
            ("L" (:shift) "move :east .")
            ("J" (:shift) "move :south .")
            ;;
            ("Z" nil "rotate .")
            ("X" nil "act .")
            ("C" nil "pop .")
            ("0" (:control) "do-exit .")
            ;;
            ("F1" nil "help .")
            ("H" (:control) "help .")
            ("P" (:control) "pause .")
            ("PAUSE" nil "pause .")
            ("ESCAPE" nil "restart .")
            ("Q" (:control) "quit ."))))
  
(define-prototype void-prompt (:parent xe2:=prompt=))

(define-method install-keybindings void-prompt ()
(message "installing keybindings...")
  (dolist (k *qwerty-keybindings*)
    (apply #'bind-key-to-prompt-insertion self k)))

;; (define-method handle-key void-prompt (keylist)
;;   (message "handling ~S" keylist)
;;   [parent>>handle-key self keylist])

;; (define-method install-keybindings void-prompt ()
;;   (let ((keys (ecase xe2:*user-keyboard-layout* 
;;              (:qwerty *qwerty-keybindings*)
;;              (:alternate-qwerty *alternate-qwerty-keybindings*)
;;              (:dvorak *dvorak-keybindings*))))
;;     (dolist (k keys)
;;       (apply #'bind-key-to-prompt-insertion self k))))
(defun physics (&rest ignore)
  (when *world* [run-cpu-phase *world* t])
  (when *status* [update *status*]))
(defparameter *dust-particle-sparkle-interval* 2000)
(defparameter *dust-particle-sparkle-time* 4)

(defsprite dust-particle
  (image :initform "dust-off")
  (speed :initform (make-stat :min 0 :base 1))
  (direction :initform (random-direction))
  (interval-clock :initform (random *dust-particle-sparkle-interval*))
  (sparkle-clock :initform 0))

(define-method run dust-particle ()
  (with-fields (interval-clock direction sparkle-clock image) self
    (when (zerop interval-clock)
      (setf direction (random-direction))
      (setf sparkle-clock *dust-particle-sparkle-time*)
      (setf interval-clock *dust-particle-sparkle-interval*))
    (setf image
          (if (plusp sparkle-clock)
              (if (evenp sparkle-clock)
                  "dust-white"
                  "dust-cyan")
              "dust-off"))
    (decf interval-clock)
    (decf sparkle-clock)
    (percent-of-time 30 [move self direction 1])))

(defun same-team (obj1 obj2)
  (eq (field-value :team obj1)
      (field-value :team obj2)))

;;; Glittering flash gives clues on locations of explosions/damage

(defcell flash 
  (clock :initform 2)
  (tile :initform "flash-1")
  (categories :initform '(:actor))
  (speed :initform (make-stat :base 1)))

(define-method run flash ()
  [expend-action-points self 10]
  (case <clock>
    (1 (setf <tile> "flash-2"))
    (0 [>>die self]))
  (decf <clock>))

;;; Sparkle is a bigger but faster flash.

(defcell sparkle 
  (clock :initform 1)
  (tile :initform "sparkle")
  (categories :initform '(:actor))
  (speed :initform (make-stat :base 1)))

(define-method run sparkle ()
  [expend-action-points self 20]
  (case <clock>
    (1 (setf <tile> "sparkle"))
    (0 [die self]))
  (decf <clock>))

;;; An explosion.

(defcell explosion 
  (name :initform "Explosion")
  (categories :initform '(:actor :target))
  (tile :initform "explosion")
  (speed :initform (make-stat :base 4))
  (damage-per-turn :initform 10)
  (clock :initform 6))

(define-method run explosion ()
  (if (zerop <clock>)
      [die self]
      (progn
        (setf <tile> (car (one-of '("explosion" "explosion2"))))
        (percent-of-time 30 [play-sample self "crunch"])
        (decf <clock>)
        (percent-of-time 80 [move self (random-direction)])
        [expend-action-points self 10]
        (xe2:do-cells (cell [cells-at *world* <row> <column>])
          [damage cell <damage-per-turn>]))))

;;; Particle gun

(defcell buster-particle 
  (tile :initform "blueparticle")
  (movement-cost :initform (make-stat :base 0))
  (speed :initform (make-stat :base 5 :min 0 :max 10))
  (team :initform :player)
  (categories :initform '(:actor :particle :target))
  (direction :initform :north))

(define-method initialize buster-particle (direction)
  (setf <direction> direction))

(define-method run buster-particle ()
  (multiple-value-bind (r c) (step-in-direction <row> <column> <direction>)
    (let ((obs [obstacle-at-p *world* r c]))
      (if obs
          (cond ((eq t obs)
                 ;; out of bounds.
                 [die self])
                ((clon:object-p obs)
                 ;; hit it
                 (let ((thing (or [category-at-p *world* r c :target] obs)))
                   (if (null thing)
                       [move self <direction>]
                       (progn 
                         (when [in-category thing :puck]
                           [kick thing <direction>])
                         (when (and (clon:has-method :hit thing)
                                    (not (same-team self thing)))
                           [drop self (clone =flash=)]
                           [hit thing])
                         [die self])))))
          [move self <direction>]))))

(defcell buster-defun
  (name :initform "Buster gun")
  (description :initform 
"The BUSTER program fires a relatively weak particle weapon when activated.
However, ammunition is unlimited, making BUSTER an old standby.")
  (tile :initform "buster")
  (energy-cost :initform 0)
  (call-interval :initform 7)
  (clock :initform 0)
  (categories :initform '(:item :target :defun)))

(define-method call buster-defun (caller)
  (clon:with-field-values (direction row column) caller
    [play-sample caller "fire"]
    [drop-cell *world* (clone =buster-particle= direction) row column]))

;;; A bomb with countdown display.

(defvar *bomb-tiles* '("bomb-1" "bomb-2" "bomb-3" "bomb-4"))

(defun bomb-tile (n)
  (nth (truncate (/ (- n 1) 30)) *bomb-tiles*))

(defcell bomb 
  (categories :initform '(:actor :puck :target :obstacle))
  (clock :initform 120)
  (team :initform :enemy)
  (direction :initform nil)
  (speed :initform (make-stat :base 1))
  (tile :initform (bomb-tile 4)))

(define-method kick bomb (direction)
  (setf <direction> direction))

(define-method run bomb () 
  (clon:with-fields (clock direction) self             
    (if (zerop clock) 
        [explode self]
        (progn 
          (when (and direction (evenp clock))
            (multiple-value-bind (r c) 
                (step-in-direction <row> <column> direction)
              (if [obstacle-at-p *world* r c]
                  (setf direction nil)
                  [move-cell *world* self r c])))
          (when (zerop (mod clock 30))
            (setf <tile> (bomb-tile clock))
            [play-sample self "countdown"]
            (dotimes (n 10)
              [drop self (clone =particle=)]))
          (decf clock)))))

(define-method explode bomb ()  
  (labels ((boom (r c &optional (probability 70))
             (prog1 nil
;;             (message "BOOM ~S" (list r c))
               (when (and (< (random 100) probability)
                          [in-bounds-p *world* r c]
                          [can-see-* self r c :barrier])
                 [drop-cell *world* (clone =explosion=) r c :no-collisions nil])))
           (damage (r c &optional (probability 100))
             (prog1 nil
;;             (message "DAMAGE ~S" (list r c))
               (when (and (< (random 100) probability)
                          [in-bounds-p *world* r c]
                          [can-see-* self r c :obstacle])
                 (do-cells (cell [cells-at *world* r c])
                   (when (clon:has-method :damage cell)
                     [damage cell 16])
                   (when (clon:has-method :hit cell)
                     [hit cell]))))))
    ;; definitely damage everything in radius
    (trace-rectangle #'damage
                     (- <row> 2) 
                     (- <column> 2) 
                     5 5 :fill)
    ;; immediately adjacent explosions
    (dolist (dir xe2:*compass-directions*)
      (multiple-value-bind (r c)
          (step-in-direction <row> <column> dir)
        (boom r c 100)))
    ;; randomly sprinkle some fire around edges
    (trace-rectangle #'boom 
                     (- <row> 2) 
                     (- <column> 2) 
                     5 5)
    (trace-rectangle #'boom 
                     (- <row> 3) 
                     (- <column> 3) 
                     7 7)
    ;; ever-present sparkles
    (dotimes (n (+ 10 (random 10)))
      [drop self (clone =plasma=)])
    ;; circular flash
    (labels ((do-circle (image)
               (prog1 t
                 (multiple-value-bind (x y) 
                     [screen-coordinates self]
                   (let ((x0 (+ x 8))
                         (y0 (+ y 8)))
                     (draw-circle x0 y0 40 :destination image)
                     (draw-circle x0 y0 35 :destination image))))))
      [>>add-overlay :viewport #'do-circle])
    [die self]))

(defcell bomb-defun
  (name :initform "Bomb")
  (description :initform "This single-use BOMB program drops a timed explosive device.")
  (tile :initform "bomb-ammo")
  (energy-cost :initform 5)
  (call-interval :initform 20)
  (categories :initform '(:item :target :defun)))

(define-method call bomb-defun (caller)
  (clon:with-field-values (direction row column) caller
    (multiple-value-bind (r c) (step-in-direction row column direction)
      (if [obstacle-at-p *world* r c]
          (progn [play-sample self "error"]
                 [say self "Cannot drop bomb here."])
          (progn [play-sample caller "fire"]
                 [drop-cell *world* (clone =bomb=) r c]
                 [expend-item caller])))))

;;; Bomb cannon

(defcell bomb-cannon
  (categories :initform '(:item :weapon :equipment))
  (attack-cost :initform (make-stat :base 5))
  (weight :initform 3000)
  (equip-for :initform '(:right-bay :robotic-arm)))

(define-method activate bomb-cannon ()
  ;; leave bomb on top of ship
  (clon:with-field-values (row column) <equipper>
    [drop-cell *world* (clone =bomb=) row column]))

(define-method fire bomb-cannon (direction)
  (clon:with-field-values (last-direction row column) <equipper>
    (multiple-value-bind (r c) 
        (step-in-direction row column direction)
      [drop-cell *world* (clone =bomb=) r c :no-collisions t])))

;;; The exploding mine

(defcell mine 
  (name :initform "Proximity mine")
  (categories :initform '(:item :target :actor :hidden))
  (tile :initform "mine")
  (description :initform "If you get near it, it will probably explode."))

(defvar *mine-warning-sensitivity* 5)
(defvar *mine-explosion-sensitivity* 3)

(define-method run mine ()
  (let ((distance [distance-to-player *world* <row> <column>]))
    (if (< distance *mine-warning-sensitivity*)
        (progn
          (when (string= <tile> "mine")
            [>>say :narrator "You see a mine nearby!"])
          (setf <tile> "mine-warn")
          (when (< distance *mine-explosion-sensitivity*)
            (when (< (random 8) 1)
              [explode self])))
        (setf <tile> "mine"))))

(define-method explode mine ()
  (labels ((boom (r c &optional (probability 50))
             (prog1 nil
               (when (and (< (random 100) probability)
                          [in-bounds-p *world* r c])
                 [drop-cell *world* (clone =explosion=) r c :no-collisions nil]))))
    (dolist (dir xe2:*compass-directions*)
      (multiple-value-bind (r c)
          (step-in-direction <row> <column> dir)
        (boom r c 100)))
    ;; randomly sprinkle some fire around edges
    (trace-rectangle #'boom 
                     (- <row> 2) 
                     (- <column> 2) 
                     5 5)
    [die self]))

(define-method step mine (stepper)
  (when [is-player stepper]           
    [explode self]))

(define-method damage mine (damage-points)
  (declare (ignore damage-points))
  [explode self])

;;; Muon particles, trails, and pistols

(defvar *muon-tiles* '(:north "muon-north"
                       :south "muon-south"
                       :east "muon-east"
                       :west "muon-west"
                       :northeast "muon-northeast"
                       :southeast "muon-southeast"
                       :southwest "muon-southwest"
                       :northwest "muon-northwest"))

(defvar *trail-middle-tiles* '(:north "bullet-trail-middle-north"
                               :south "bullet-trail-middle-south"
                               :east "bullet-trail-middle-east"
                               :west "bullet-trail-middle-west"
                               :northeast "bullet-trail-middle-northeast"
                               :southeast "bullet-trail-middle-southeast"
                               :southwest "bullet-trail-middle-southwest"
                               :northwest "bullet-trail-middle-northwest"))

(defvar *trail-end-tiles* '(:north "bullet-trail-end-north"
                               :south "bullet-trail-end-south"
                               :east "bullet-trail-end-east"
                               :west "bullet-trail-end-west"
                               :northeast "bullet-trail-end-northeast"
                               :southeast "bullet-trail-end-southeast"
                               :southwest "bullet-trail-end-southwest"
                               :northwest "bullet-trail-end-northwest"))

(defvar *trail-tile-map* (list *trail-end-tiles* *trail-middle-tiles* *trail-middle-tiles*))

(defcell muon-trail
  (categories :initform '(:actor))
  (clock :initform 2)
  (speed :initform (make-stat :base 10))
  (default-cost :initform (make-stat :base 10))
  (tile :initform ".gear")
  (direction :initform :north))

(define-method orient muon-trail (direction)
  (setf <direction> direction)
  (setf <tile> (getf *trail-middle-tiles* direction)))

(define-method run muon-trail ()
  (setf <tile> (getf (nth <clock> *trail-tile-map*)
                     <direction>))
  [expend-default-action-points self]
  (decf <clock>)
  (when (minusp <clock>)
    [die self]))

;;; Basic muon particle

(defcell muon-particle 
  (categories :initform '(:actor :muon :target))
  (speed :initform (make-stat :base 22))
  (default-cost :initform (make-stat :base 3))
  (attack-power :initform 5)
  (tile :initform "muon")
  (firing-sound :initform "dtmf2")
  (direction :initform :here)
  (clock :initform 12))

(define-method initialize muon-particle (&key attack-power)
  (when attack-power
    (setf <attack-power> attack-power)))

(define-method drop-trail muon-particle (direction)
  (let ((trail (clone =muon-trail=)))
    [orient trail direction]
    [drop self trail]))

(define-method find-target muon-particle ()
  (let ((target [category-in-direction-p *world* 
                                         <row> <column> <direction>
                                         '(:obstacle :target)]))
    (if target
        (progn
          [>>move self <direction>]
          [>>expend-default-action-points self]
          [>>drop target (clone =flash=)]
          ;;[>>push target <direction>]
          [>>damage target <attack-power>]
          [>>die self])
        (multiple-value-bind (r c) 
            (step-in-direction <row> <column> <direction>)
          (if (not (array-in-bounds-p (field-value :grid *world*) r c))
              [die self]
              (progn [drop-trail self <direction>]
                     [>>move self <direction>]))))))

(define-method step muon-particle (stepper)
  [damage stepper <attack-power>]
  [die self])
  
(define-method update-tile muon-particle ()
  (setf <tile> (getf *muon-tiles* <direction>)))

(define-method run muon-particle ()
  [update-tile self]
  [find-target self]
  (decf <clock>)
  (when (zerop <clock>)
    [>>die self]))

(define-method impel muon-particle (direction)
  (assert (member direction *compass-directions*))
  (setf <direction> direction)
  ;; don't hit the player
  ;;  [move self direction]
  [play-sample self <firing-sound>]
  [find-target self])

;;; Beta-muons

(define-prototype beta-muon (:parent =muon-particle=)
  (speed :initform (make-stat :base 24))
  (attack-power :initform 8)
  (firing-sound :initform "dtmf3")
  (tile :initform "beta-muon")
  (clock :initform 15))
  
(defvar *beta-muon-tiles* '(:north "beta-muon-north"
                            :south "beta-muon-south"
                            :east "beta-muon-east"
                            :west "beta-muon-west"
                            :northeast "beta-muon-northeast"
                            :southeast "beta-muon-southeast"
                            :southwest "beta-muon-southwest"
                            :northwest "beta-muon-northwest"))

(define-method update-tile beta-muon ()
  (setf <tile> (getf *beta-muon-tiles* <direction>)))

;;; Muon cannon

(defcell muon-cannon
  (name :initform "Muon energy cannon")
  (tile :initform "gun")
  (ammo :initform =muon-particle=)
  (categories :initform '(:item :weapon :equipment))
  (equip-for :initform '(:center-bay))
  (weight :initform 7000)
  (accuracy :initform (make-stat :base 100))
  (attack-power :initform (make-stat :base 12))
  (attack-cost :initform (make-stat :base 10))
  (energy-cost :initform (make-stat :base 1)))

(define-method change-ammo muon-cannon (ammo)
  (assert (clon:object-p ammo))
  (setf <ammo> ammo))

(define-method fire muon-cannon (direction)
  (if [expend-energy <equipper> [stat-value self :energy-cost]]
      (let ((bullet (clone <ammo>)))
        [>>drop <equipper> bullet]
        [>>impel bullet direction])
      [say <equipper> "Not enough energy to fire!"]))

(define-method step muon-cannon (stepper)
  (when [is-player stepper]
    [>>take stepper :direction :here :category :item]))

;;; Phonic particles

(defcell particle 
  (tile :initform "particle")
  (direction :initform (car (one-of '(:north :south :east :west))))
  (categories :initform '(:actor))
  (clock :initform (random 20)))

(define-method run particle ()
  (decf <clock>)
  (setf <tile> (car (one-of '("particle" "particle2" "particle3"))))
  ;;[play-sample self "particle-sound-1"]
  (if (minusp <clock>) [die self]
      [move self <direction>]))

;;; Phi particles

(defcell phi
  (tile :initform "phi")
  (direction :initform (car (one-of '(:north :northeast :northwest :southeast :southwest :south :east :west))))
  (categories :initform '(:actor))
  (clock :initform (random 20)))

(define-method run phi ()
  (decf <clock>)
  (setf <tile> (car (one-of '("phi" "phi2" "phi3"))))
  ;;[play-sample self "particle-sound-1"]
  (if (minusp <clock>) 
      [die self]
      (progn (percent-of-time 3 [play-sample self (car (one-of '("dtmf1" "dtmf2" "dtmf3")))])
             [move self <direction>])))

;;; Shield restore pack

(defcell shield-pack
  (name :initform "Shield pack")
  (description :initform "This shield pack restores some shield energy.")
  (tile :initform "health")
  (energy-cost :initform 0)
  (call-interval :initform 20)
  (categories :initform '(:item :defun)))

(define-method call shield-pack (caller)
  (when [is-player caller]
    [stat-effect caller :hit-points 10]
    [play-sample self "speedup"]
    [play-sample self "vox-repair"]
    [emote caller "Recovered 10 shield points."]
    [expend-item caller]))

;;; Shield

(defcell shield
  (tile :initform "shield")
  (description :initform "Wave shield blocks sound waves.")
  (team :initform :neutral)
  (default-cost :initform (make-stat :base 10))
  (speed :initform (make-stat :base 20))
  (hit-points :initform (make-stat :base 5 :min 0))
  (categories :initform '(:actor :target)))

(define-method hit shield (&optional wave)
  (when [in-category wave :wave]
    [play-sample self "ice"]
    [damage self 1]))

(define-method run shield () nil)

;;; White noise

(defcell noise 
  (tile :initform (car (one-of '("white-noise" "white-noise2" "white-noise3" "white-noise4"))))
  (categories :initform '(:actor))
  (clock :initform (random 20)))

(define-method run noise ()
  (decf <clock>)
  [play-sample self "noise-white"]
  (if (minusp <clock>) [die self]
      [move self (random-direction)]))

;;; Radioactive gas

(defcell gas
  (tile :initform "rad")
  (name :initform "Radioactive Gas")
  (clock :initform 100)
  (categories :initform '(:actor))
  (description :initform "Spreading toxic radioactive gas. Avoid at all costs!"))

(define-method step gas (stepper)
  (when [is-player stepper]
    [damage stepper 5]
    [>>say :narrator "RADIOACTIVE HAZARD!"]))

(define-method run gas ()
  [play-sample self "gas-poof"]
  (decf <clock>)
  (if (> 0 <clock>)
      [die self]
      (progn 
        (do-cells (cell [cells-at *world* <row> <column>])
          (when [is-player cell]
            [damage cell 5]
            [>>say :narrator "RADIOACTIVE HAZARD!"]))
        [move self (random-direction)])))

;;; A melee weapon: the Shock Probe

(defcell shock-probe 
  (name :initform "Shock probe")
  (categories :initform '(:item :weapon :equipment))
  (tile :initform "shock-probe")
  (attack-power :initform (make-stat :base 5))
  (attack-cost :initform (make-stat :base 6))
  (accuracy :initform (make-stat :base 90))
  (stepping :initform t)
  (weight :initform 3000)
  (equip-for :initform '(:robotic-arm :left-hand :right-hand)))

(define-prototype shock-prod (:parent =shock-probe=)
  (name :initform "Shock prod")
  (attack-power :initform (make-stat :base 7))
  (attack-cost :initform (make-stat :base 12))
  (accuracy :initform (make-stat :base 80)))
  
;;; Lepton Seeker Cannon

(defvar *lepton-tiles* '(:north "lepton-north"
                       :south "lepton-south"
                       :east "lepton-east"
                       :west "lepton-west"
                       :northeast "lepton-northeast"
                       :southeast "lepton-southeast"
                       :southwest "lepton-southwest"
                       :northwest "lepton-northwest"))

(defvar *lepton-trail-middle-tiles* '(:north "bullet-trail-middle-thin-north"
                               :south "bullet-trail-middle-thin-south"
                               :east "bullet-trail-middle-thin-east"
                               :west "bullet-trail-middle-thin-west"
                               :northeast "bullet-trail-middle-thin-northeast"
                               :southeast "bullet-trail-middle-thin-southeast"
                               :southwest "bullet-trail-middle-thin-southwest"
                               :northwest "bullet-trail-middle-thin-northwest"))

(defvar *lepton-trail-end-tiles* '(:north "bullet-trail-end-thin-north"
                               :south "bullet-trail-end-thin-south"
                               :east "bullet-trail-end-thin-east"
                               :west "bullet-trail-end-thin-west"
                               :northeast "bullet-trail-end-thin-northeast"
                               :southeast "bullet-trail-end-thin-southeast"
                               :southwest "bullet-trail-end-thin-southwest"
                               :northwest "bullet-trail-end-thin-northwest"))

(defvar *lepton-trail-tile-map* (list *lepton-trail-end-tiles* *lepton-trail-middle-tiles* *lepton-trail-middle-tiles*))

(define-prototype lepton-trail (:parent xe2:=cell=)
  (categories :initform '(:actor))
  (clock :initform 2)
  (speed :initform (make-stat :base 10))
  (default-cost :initform (make-stat :base 10))
  (tile :initform ".gear")
  (direction :initform :north))

(define-method initialize lepton-trail (direction)
  (setf <direction> direction)
  (setf <tile> (getf *lepton-trail-middle-tiles* direction)))

(define-method run lepton-trail ()
  (setf <tile> (getf (nth <clock> *lepton-trail-tile-map*)
                     <direction>))
  [expend-default-action-points self]
  (decf <clock>)
  (when (minusp <clock>)
    [die self]))

(define-prototype lepton-particle (:parent xe2:=cell=)
  (categories :initform '(:actor :target :lepton))
  (speed :initform (make-stat :base 8))
  (seeking :initform :player)
  (team :initform :player)
  (stepping :initform t)
  (hit-damage :initform (make-stat :base 7))
  (default-cost :initform (make-stat :base 2))
  (hit-points :initform (make-stat :base 5))
  (movement-cost :initform (make-stat :base 4))
  (tile :initform "lepton")
  (direction :initform :here)
  (clock :initform 10))

(define-method find-target lepton-particle ()
  (let ((target [category-in-direction-p *world* 
                                         <row> <column> <direction>
                                         '(:obstacle :target)]))
    (if target
        (unless (same-team self target) 
          (dotimes (n 3)
            [drop target (clone =explosion=)])
          [damage target [stat-value self :hit-damage]]
          [play-sample target "serve"]
          (labels ((do-circle (image)
                     (prog1 t
                       (multiple-value-bind (x y) 
                           [screen-coordinates self]
                         (let ((x0 (+ x 8))
                               (y0 (+ y 8)))
                           (draw-circle x0 y0 40 :destination image)
                           (draw-circle x0 y0 35 :destination image))))))
            [>>add-overlay :viewport #'do-circle])
          [die self])
        (progn 
          [drop self (clone =lepton-trail= <direction>)]
          [move self <direction>]))))

(define-method update-tile lepton-particle ()
  (setf <tile> (getf *lepton-tiles* <direction>)))
  
(define-method seek-direction lepton-particle ()
  (ecase <seeking>
    (:player [direction-to-player *world* row column])
    (:enemy (let (enemies)
              (labels ((find-enemies (r c)
                         (let ((enemy [enemy-at-p *world* r c]))
                           (prog1 nil
                             (when enemy
                               (when [can-see self enemy :barrier]
                                 (push enemy enemies)))))))
                (trace-rectangle #'find-enemies (- <row> 3) (- <column> 3) 7 7 :fill))
              (if enemies
                  (multiple-value-bind (row column) [grid-coordinates (car enemies)]
                    (direction-to <row> <column> row column))
                  <direction>)))))
                
(define-method run lepton-particle ()
  [update-tile self]
  (clon:with-field-values (row column) self
    (let* ((world *world*)
           (direction [seek-direction self]))
      (setf <direction> direction)
      [find-target self])
    (decf <clock>)
    (when (and (zerop <clock>) 
               (not [in-category self :dead]))
      [>>die self])))

(define-method seek lepton-particle (key)
  (setf <seeking> key))

(define-method damage lepton-particle (points)
  (declare (ignore points))
  [drop self (clone =sparkle=)]
  [die self])
      
(define-method impel lepton-particle (direction)
  (assert (member direction *compass-directions*))
  (setf <direction> direction)
  ;; don't hit the player
  [find-target self])

(define-prototype lepton-cannon (:parent xe2:=cell=)
  (name :initform "Xiong Les Fleurs Lepton(TM) energy cannon")
  (tile :initform "lepton-cannon")
  (categories :initform '(:item :weapon :equipment))
  (equip-for :initform '(:robotic-arm))
  (weight :initform 14000)
  (accuracy :initform (make-stat :base 60))
  (attack-power :initform (make-stat :base 16))
  (attack-cost :initform (make-stat :base 25))
  (energy-cost :initform (make-stat :base 32)))

(define-method fire lepton-cannon (direction)
  (if [expend-energy <equipper> [stat-value self :energy-cost]]
      (let ((lepton (clone =lepton-particle=)))
        [play-sample <equipper> "bloup"]
        [drop <equipper> lepton]
        [impel lepton direction]
        [expend-action-points <equipper> [stat-value self :attack-cost]]
      (message "Not enough energy to fire."))))

;;; Lepton weapon for player

(defcell lepton-defun
  (name :initform "Lepton homing missile")
  (description :initform 
"The LEPTON program fires a strong homing missile.")
  (tile :initform "lepton-defun")
  (energy-cost :initform 5)
  (call-interval :initform 20)
  (categories :initform '(:item :target :defun)))

(define-method call lepton-defun (caller)
  (clon:with-field-values (direction row column) caller
    (let ((lepton (clone =lepton-particle=)))
      [play-sample caller "bloup"]
      [drop caller lepton]
      [seek lepton :enemy]
      [impel lepton direction])))

;;; There are also energy tanks for replenishing ammo.

(defcell energy 
  (tile :initform "energy")
  (name :initform "Energy refill")
  (description :initform "Refills part of your energy store.")
  (energy-cost :initform 0)
  (call-interval :initform 20)
  (categories :initform '(:item :target :defun)))

(define-method call energy (caller)
  [play-sample caller "whoop"]
  [stat-effect caller :energy 20]
  [expend-item caller])

(defcell energy-tank
  (tile :initform "energy-max-up")
  (name :initform "Energy Tank")
  (description :initform "Increases maximum energy store by 15.")
  (energy-cost :initform 0)
  (call-interval :initform 20)
  (categories :initform '(:item :target :defun)))

(define-method call energy-tank (caller)
  [play-sample caller "fanfare"]
  [stat-effect caller :energy 15 :max]
  [>>narrateln :narrator "Increased max energy by 15!" :foreground ".yellow" :background ".blue"]
  [expend-item caller])

;;; An exploding missile.

(defvar *missile-trail-tile-map* (list *lepton-trail-end-tiles* *lepton-trail-middle-tiles* *lepton-trail-middle-tiles*))

(defvar *missile-tiles* '(:north "missile-north"
                       :south "missile-south"
                       :east "missile-east"
                       :west "missile-west"
                       :northeast "missile-northeast"
                       :southeast "missile-southeast"
                       :southwest "missile-southwest"
                       :northwest "missile-northwest"))

(define-prototype missile (:parent =lepton-particle=)
  (speed :initform (make-stat :base 25))
  (hit-damage :initform (make-stat :base 10))
  (hit-points :initform (make-stat :base 10))
  (tile :initform "missile-north")
  (clock :initform 20))

(define-method update-tile missile ()
  (setf <tile> (or (getf *missile-tiles* <direction>)
                   "missile-north")))

(define-method die missile ()
  [drop self (clone =explosion=)]
  [parent>>die self])

;;; Multi-warhead missile

(defvar *multi-missile-tiles* '(:north "multi-missile-north"
                       :south "multi-missile-south"
                       :east "multi-missile-east"
                       :west "multi-missile-west"
                       :northeast "multi-missile-northeast"
                       :southeast "multi-missile-southeast"
                       :southwest "multi-missile-southwest"
                       :northwest "multi-missile-northwest"))

(define-prototype multi-missile (:parent =missile=)
  (tile :initform "multi-missile-north")
  (clock :initform 12)
  (hit-damage :initform (make-stat :base 18))
  (hit-points :initform (make-stat :base 20)))

(define-method update-tile multi-missile ()
  (setf <tile> (or (getf *multi-missile-tiles* <direction>)
                   "multi-missile-north")))

(define-method run multi-missile ()
  [update-tile self]
  (if (or (= 0 <clock>)
          (> 7 [distance-to-player self]))
      ;; release warheads
      (progn 
        (dolist (dir (list :northeast :southeast :northwest :southwest))
          (multiple-value-bind (r c) 
              (step-in-direction <row> <column> dir)
            [drop-cell *world* (clone =missile=) r c]))
        [die self])
      ;; move toward player
      (progn (decf <clock>)
             [parent>>run self])))

(define-method die multi-missile ()
  [drop self (clone =flash=)]
  [parent>>die self])
  
;;; Missile launchers

(define-prototype missile-launcher (:parent =lepton-cannon=)
  (ammo :initform =missile=)
  (attack-cost :initform (make-stat :base 20)))

(define-method fire missile-launcher (direction)
  (let ((missile (clone <ammo>)))
    [play-sample <equipper> "bloup"]
    [>>drop <equipper> missile]
    [>>impel missile direction]
    [expend-action-points <equipper> [stat-value self :attack-cost]]))

(define-prototype multi-missile-launcher (:parent =missile-launcher=)
  (ammo :initform =multi-missile=)
  (attack-cost :initform (make-stat :base 80)))
(defparameter *waveforms* '(:sine :square :saw :bass))
(defparameter *wave-colors* '(:yellow :cyan :magenta :green))

(defparameter *wave-samples*
  '((:sine "A-2-sine" "A-4-sine")
    (:saw "A-2-saw" "A-4-saw")
    (:square "A-2-square" "A-4-square")))

(defun wave-sample (type &optional (note "A-4"))
  (assert (member type *waveforms*))
  (concatenate 'string note "-" (string-downcase (symbol-name type))))

(defparameter *wave-images*
  '((:sine :green "sine-green" :yellow "sine-yellow" :magenta "sine-magenta" :cyan "sine-cyan")
    (:square :green "square-green" :yellow "square-yellow" :magenta "square-magenta" :cyan "square-cyan")
    (:saw :green "saw-green" :yellow "saw-yellow" :magenta "saw-magenta" :cyan "saw-cyan")))

(defun wave-image (type &optional (color :green))
  (assert (and (member type *waveforms*)
               (member color *wave-colors*)))
  (getf (cdr (assoc type *wave-images*))
        color))

(defparameter *pulse-delay* 8)

(defsprite wave
  (description :initform "A sonic wave.")
  (team :initform :player)
  (color :initform :green)
  (waveform :initform :sine)
  (note :initform "A-4")
  (clock :initform 60)
  (pulse :initform (random *pulse-delay*))
  (image :initform nil)
  (direction :initform nil)
  (speed :initform (make-stat :base 20))
  (movement-distance :initform (make-stat :base 2))
  (movement-cost :initform (make-stat :base 20))
  (categories :initform '(:wave :actor)))

(define-method start wave (&key (note "A-4") (waveform :sine) (direction :north) (team :player) (color :green))
  (setf <waveform> waveform)
  (setf <team> team)
  (setf <note> note)
  [update-image self (wave-image waveform color)]
  (setf <sample> (wave-sample waveform note))
  (setf <direction> direction))

(define-method run wave ()
  (decf <clock>)
  (if (minusp <clock>)
      [die self]
      (progn [expend-action-points self 2]
             (when <direction> 
               (multiple-value-bind (y x) (xe2:step-in-direction <y> <x> <direction>
                                                                 [stat-value self :movement-distance])
                 [update-position self x y])
               ;; decide whether to beep.
               (if (zerop <pulse>)
                   (progn (setf <pulse> *pulse-delay*)
                          [play-sample self <sample>])
                   (decf <pulse>))))))

(define-method refresh wave ()
  (setf <clock> 60))

(define-method do-collision wave (object)
  (when (and (not [in-category object :wave])
             [in-category object :target]
             (has-field :team object)
             (not (eq <team> (field-value :team object))))
    [hit object self]
    (when [in-category object :particle]
      [die object])
    [die self]))

(defparameter *wave-cannon-reload-time* 40)

(defcell wave-cannon
  (tile :initform "gun")
  (reload-clock :initform 0)
  (categories :initform '(:item :weapon :equipment))
  (equip-for :initform '(:center-bay))
  (weight :initform 7000)
  (accuracy :initform (make-stat :base 100))
  (attack-power :initform (make-stat :base 12))
  (attack-cost :initform (make-stat :base 10))
  (energy-cost :initform (make-stat :base 0)))

(define-method fire wave-cannon (direction)
  (if (plusp <reload-clock>)
      nil ;; (decf <reload-clock>)
      (progn 
        (setf <reload-clock> *wave-cannon-reload-time*)
        (if [expend-energy <equipper> [stat-value self :energy-cost]]
            (let ((wave (clone =wave=)))
              (multiple-value-bind (x y) [viewport-coordinates <equipper>]
                [drop-sprite <equipper> wave (+ x 4) (+ y 4)]
                [start wave :direction direction :team (field-value :team <equipper>)
                       :color (field-value :color <equipper>)
;;                     :note (car (one-of (list "A-4"  "A-2")))
                       :waveform (field-value :waveform <equipper>)]))
            (when [is-player <equipper>]
              [say <equipper> "Not enough energy to fire!"])))))

(define-method recharge wave-cannon ()
  (decf <reload-clock>))

(defcell shocker 
  (tile :initform "shocker")
  (auto-loadout :initform t)
  (description :initform "Creeps about until catching sight of the player;
Then it fires and gives chase.")
  (team :initform :enemy)
  (color :initform :cyan)
  (waveform :initform :square)
  (hit-points :initform (make-stat :base 2 :min 0 :max 45))
  (movement-cost :initform (make-stat :base 10))
  (max-items :initform (make-stat :base 2))
  (speed :initform (make-stat :base 5 :min 0 :max 25))
  (strength :initform (make-stat :base 10))
  (defense :initform (make-stat :base 10))
  (hearing-range :initform 15)
  (energy :initform (make-stat :base 40 :min 0 :max 40 :unit :gj))
  (movement-cost :initform (make-stat :base 10))
  (max-items :initform (make-stat :base 2))
  (stepping :initform t)
  (direction :initform :north)
  (attacking-with :initform nil)
  (firing-with :initform :center-bay)
  (categories :initform '(:actor :obstacle  :target :container :light-source :vehicle :repairable :enemy))
  (equipment-slots :initform '(:left-bay :right-bay :center-bay :extension)))

(define-method loadout shocker ()
  [make-inventory self]
  [make-equipment self]
  [equip self [add-item self (clone =wave-cannon=)]])

(define-method hit shocker (&optional object)
  [die self])

(define-method run shocker ()
  (let ((cannon [equipment-slot self :center-bay]))
    (when cannon [recharge cannon]))
  (let ((dir [direction-to-player self])
        (dist [distance-to-player self]))
    (if (< dist 13)
        (if (> 9 dist)
            (progn [fire self dir]
                   [expend-action-points self 100]
                   (xe2:percent-of-time 3 [move self dir]))
            (if [obstacle-in-direction-p *world* <row> <column> dir]
                [move self (random-direction)]
                [move self dir]))
        (if (percent-of-time 3 [move self (random-direction)])
            [expend-action-points self 10]))))

(define-method die shocker () 
  (dotimes (n 10)
    [drop self (clone =noise=)])
  (percent-of-time 12 [drop self (clone =shield-pack=)])
  [play-sample self "yelp"]
  [parent>>die self])
;;; Corruption

(defcell corruption 
  (tile :initform "corruption-east")
  (description :initform "Deadly digital audio data corruption.")
  (direction :initform :east)
  (clock :initform 100)
  (categories :initform '(:actor)))
 
(define-method step corruption (stepper)
  (when [is-player stepper]
    [die stepper]))

(define-method orient corruption (&optional dir)
  (when dir (setf <direction> dir))
  (setf <tile> (if (= 0 (random 2))
                   (ecase <direction>
                     (:north "corruption-north")
                     (:south "corruption-south")
                     (:east "corruption-east")
                     (:west "corruption-west"))
                   (ecase <direction>
                     (:north "corruption2-north")
                     (:south "corruption2-south")
                     (:east "corruption2-east")
                     (:west "corruption2-west")))))

(define-method run corruption ()
  (decf <clock>)
  (percent-of-time 5 [play-sample self "datanoise"])
  (if (plusp <clock>)
      [orient self]
      [die self]))

;;; Corruptors who leave a trail of digital audio corruption 

(defcell corruptor 
  (tile :initform "corruptor")
  (description :initform "Corruptors traverse the level, leaving a trail of deadly malformed data.")
  (team :initform :enemy)
  (color :initform :cyan)
  (waveform :initform :saw)
  (direction :initform (xe2:random-direction))
  (movement-cost :initform (make-stat :base 20))
  (max-items :initform (make-stat :base 2))
  (speed :initform (make-stat :base 3 :min 0 :max 5))
  (strength :initform (make-stat :base 10))
  (defense :initform (make-stat :base 10))
  (hearing-range :initform 15)
  (energy :initform (make-stat :base 400 :min 0 :max 40 :unit :gj))
  (hit-points :initform (make-stat :base 8 :min 0 :max 8))
  (movement-cost :initform (make-stat :base 10))
  (max-items :initform (make-stat :base 2))
  (stepping :initform t)
  (direction :initform :north)
  (attacking-with :initform nil)
  (firing-with :initform :center-bay)
  (categories :initform '(:actor :obstacle  :target :container :light-source :vehicle :repairable))
  (equipment-slots :initform '(:left-bay :right-bay :center-bay :extension)))

(define-method loadout corruptor ()
  [make-inventory self]
  [make-equipment self]
  [equip self [add-item self (clone =wave-cannon=)]])

(define-method hit corruptor (&optional object)
  [die self])

(define-method run corruptor ()
  (let ((cannon [equipment-slot self :center-bay]))
    (when cannon [recharge cannon]))
  (let ((dir [direction-to-player self])
        (dist [distance-to-player self]))
    (when [obstacle-in-direction-p *world* <row> <column> <direction>]
      (setf <direction> (if (= 0 (random 4))
                            (ecase <direction>
                              (:north :west)
                              (:west :south)
                              (:south :east)
                              (:east :north))
                            (ecase <direction>
                              (:north :east)
                              (:west :north)
                              (:south :west)
                              (:east :south)))))
    (let ((corruption (clone =corruption=)))
      [orient corruption <direction>]
      [drop self corruption]
      [move self <direction>])))

(define-method die corruptor () 
  (dotimes (n 10)
    [drop self (clone =noise=)])
  [play-sample self "yelp"]
  [parent>>die self])  

(defsprite drone
  (description :initform "A security drone. Manufactures attacking replicant xioforms.")
  (team :initform :enemy)
  (color :initform :magenta)
  (waveform :initform :saw)
  (alarm-clock :initform 0)
  (pulse :initform (random *pulse-delay*))
  (image :initform "drone")
  (moving :initform t)
  (hit-points :initform (make-stat :base 40 :min 0))
  (direction :initform (random-direction))
  (speed :initform (make-stat :base 20))
  (movement-distance :initform (make-stat :base 2))
  (movement-cost :initform (make-stat :base 20))
  (categories :initform '(:drone :actor :target)))

(define-method run drone ()
  (percent-of-time 16 [play-sample self "sense2"])
  (when (< [distance-to-player self] 20)
    (if (zerop <alarm-clock>)
        (progn [play-sample self "alarm"]
               [say self "The drone spawns an enemy!"]
               (let ((enemy (or (percent-of-time 5 (clone =corruptor=))
                                (clone =shocker=))))
                 [drop self enemy]
                 [loadout enemy])
               (labels ((do-circle (image)
                          (prog1 t
                            (multiple-value-bind (x y) 
                                [image-coordinates self]
                              (let ((x0 (+ x 10))
                                    (y0 (+ y 10)))
                                (draw-circle x0 y0 25 :destination image)
                                (draw-circle x0 y0 30 :destination image)
                                (draw-circle x0 y0 35 :destination image)
                                (draw-circle x0 y0 40 :destination image))))))
                 [>>add-overlay :viewport #'do-circle])
               (setf <alarm-clock> 60))
        (decf <alarm-clock>))
    [move self [direction-to-player self] [stat-value self :movement-distance]]))

(define-method hit drone (&optional thing)
  (if [in-category thing :wave]
      (progn [play-sample self "yelp"]
             [damage self 1])
      [>>say :narrator "This weapon has no effect on the Drone."]))

(define-method die drone ()
  [say self "The drone is destroyed!"]
  (dotimes (n 30)
    [drop self (clone =noise=)])
  [parent>>die self])

(define-method do-collision drone (other)
  (if [is-player other]
      [die other]
      (if [in-category other :obstacle]
          ;; don't get hung up on the enemies we drop.
          (unless (and (has-field :team other)
                       (eq :enemy (field-value :team other)))
            (unless (percent-of-time 10 (setf <direction> (opposite-direction <direction>)))
              (setf <direction> (ecase <direction>
                                  (:here :west)
                                  (:northwest :west)
                                  (:northeast :east)
                                  (:north :west)
                                  (:west :south)
                                  (:southeast :east)
                                  (:southwest :south)
                                  (:south :east)
                                  (:east :north)))))
          (when (eq :player (field-value :team other))
            [damage self 2]
            [play-sample self "blaagh"]
            [die other]))))
(defsprite wire 
  (image :initform "wire-east")
  (clock :initform 20)
  (speed :initform (make-stat :base 10))
  (direction :initform :east)
  (categories :initform '(:actor :obstacle :target)))

(define-method orient wire (dir &optional (clock 5))
  (setf <direction> dir)
  (setf <clock> clock))

(define-method run wire ()
  (if (zerop <clock>) 
      [die self]
      (progn [move self <direction> 5]
             (decf <clock>)
             (percent-of-time 10 [play-sample self "woom"])
             (setf <image> (ecase <direction>
                            (:east "wire-east")
                            (:south "wire-south")
                            (:west "wire-west")
                            (:north "wire-north"))))))

(define-method do-collision wire (object)
  (when (and (has-field :team object)
             (eq :player (field-value :team object))
             [in-category object :wave])
    [die object])
  (when (and (has-field :hit-points object)
             (not (and (has-field :team object)
                       (eq :enemy (field-value :team object)))))
    [damage object 20]))

(defparameter *macrovirus-tiles*
  '("macro1" "macro2" "macro3" "macro4"))

(defcell macrovirus 
  (tile :initform "macro1")
  (team :initform :enemy)
  (generation :initform 0)
  (hit-points :initform (make-stat :base 4 :max 7 :min 0))
  (speed :initform (make-stat :base 1))
  (strength :initform (make-stat :base 10))
  (defense :initform (make-stat :base 10))
  (stepping :initform t)
  (movement-cost :initform (make-stat :base 20))
  (direction :initform (random-direction))
  (categories :initform '(:actor :obstacle :enemy :target)))

(define-method divide macrovirus ()
  [play-sample self "munch1"]
  [stat-effect self :hit-points 3]
  (dotimes (i (if (zerop (random 17))
                  2 1))
    [drop self (clone =macrovirus=)]))

(define-method hit macrovirus (&optional other)
  (when (and other [in-category other :particle])
    [die other])
  [damage self 1])

(define-method die macrovirus ()
  [play-sample self "biodeath"]
  [parent>>die self])

(define-method grow macrovirus ()
  [expend-action-points self 100]
  (incf <generation>)
  (when (= 2 <generation>)
    [divide self])
  (when (> <generation> 3)
    [die self])
  (setf <tile> (nth <generation> *macrovirus-tiles*)))

(define-method find-food macrovirus (direction)
  (let ((food [category-in-direction-p *world* <row> <column> direction :macrovirus-food]))
    (when food
      (prog1 food
        [play-sample self (if (= 0 (random 1))
                              "slurp1" "slurp2")]
        [say self "The macrovirus eats pollen."]
        [delete-from-world food]
        [move self direction]
        [grow self]))))

(define-method run macrovirus ()
  [move self (random-direction)]
  (percent-of-time 10 [grow self])
  (percent-of-time 35 (let ((direction (car (one-of (list :east :west)))))
                        (let ((muon (clone =muon-particle=)))
                          [drop self muon]
                          [impel muon direction])))
  (if (< [distance-to-player self] 6)
      (progn [move self [direction-to-player self]]
             (if [adjacent-to-player self]
                 [attack self [direction-to-player self]]))

    ;; otherwise look for food
      (block searching
        (dolist (dir xe2:*compass-directions*)
          (when (or [in-category self :dead]
                    [find-food self dir])
            (return-from searching))))))
  
(define-method attack macrovirus (direction)
  (let ((player [get-player *world*]))
    [play-sample self "munch2"]
    [damage player 3]))
(defmission gather-cloud-data 
   (:title "Gather cloud data"
    :address '(=cloud=))
  (:activate-nav-points :name "Activate all three nav points."
               :condition #'(lambda ()
                              (with-locals (alpha beta gamma)
                                (and alpha beta gamma))))
  (:return-to-base :name "Return to the Xioceptor."))
(defparameter *default-navpoint-delay* 60)

(defcell navpoint 
  (name :initform "Navpoint")
  (index :initform nil)
  (tile :initform "navpoint-off")
  (delay :initform *default-navpoint-delay*)
  (clock :initform 0)
  (trip :initform nil)
  (auto-loadout :initform t)
  (team :initform :neutral)
  (state :initform nil)  
  (speed :initform (make-stat :min 0 :base 10 :max 10))
  (categories :initform '(:target :actor :navpoint)))

(define-method initialize navpoint (index)
  (assert (keywordp index))
  (setf <index> index))
  
(define-method loadout navpoint ()
  [stop self])
  
(define-method update-tile navpoint (&optional pulsing)
  (setf <tile> (if pulsing "navpoint-on" "navpoint-off")))

(define-method tap navpoint (delay)
  (setf <delay> delay))

(define-method activate navpoint (&optional delay0)
  (with-locals (pulsing)
    (with-fields (clock delay state trip index) self
      (setf pulsing t)
      (setf clock 0)
      (when delay0 (setf delay delay0))
      (setf state t)
      (setf trip nil)
      (when (keywordp index)
        [set-variable *world* index t])
      [update-tile self])))

(define-method stop navpoint ()
  (with-locals (pulsing)
    (with-fields (index clock state) self 
      (setf state nil)
      (setf pulsing nil)
      (when (keywordp index)
        [set-variable *world* index nil])
      [update-tile self]
      (setf clock 0))))

(define-method run navpoint ()
  [update-tile self]
  (when <state>
    (if (zerop <clock>)
        (progn [play-sample self "pulse"]
               [update-tile self t]
               [set-variable *world* :pulsing t]
               (setf <trip> nil)
               (labels ((do-circle (image)
                          (prog1 t
                            (multiple-value-bind (x y) 
                                [image-coordinates self]
                              (let ((x0 (+ x 8))
                                    (y0 (+ y 8)))
                                (draw-circle x0 y0 40 :destination image)
                                (draw-circle x0 y0 35 :destination image))))))
                 [>>add-overlay :viewport #'do-circle])
               (setf <clock> <delay>))
        (progn (if <trip>
                   [set-variable *world* :pulsing nil]
                   (progn (setf <trip> t)
                          [set-variable *world* :pulsing t]))
               (decf <clock>)))))
  
(define-method step navpoint (stepper)
  (unless <state>
    (when [is-player stepper]
      [emote stepper (format nil "Activated nav point ~A." <index>)]
      [play-sample self "upwoop"]
      [activate self])))

    (defcell vaccuum 
      (tile :initform "vaccuum"))
    
    (defcell red-plasma
      (tile :initform "red-plasma"))
    
    (defcell blue-plasma
      (tile :initform "blue-plasma"))
    
    (defworld cloud
      (name :initform "DVO UV Shield Cloud")
      (scale :initform '(50 m))
      (edge-condition :initform :block)
      (background :initform "cloud")
      (ambient-light :initform :total)
      (description :initform "foo"))
      
    (define-method begin-ambient-loop cloud ()
      (play-music "passageway" :loop t))
      
    (define-method drop-plasma cloud
        (&optional &key (object =red-plasma=)
                   distance 
                   (row 0) (column 0)
                   (graininess 0.3)
                   (density 100)
                   (cutoff 0))
        (clon:with-field-values (height width) self
          (let* ((h0 (or distance height))
                 (w0 (or distance width))
                 (r0 (- row (truncate (/ h0 2))))
                 (c0 (- column (truncate (/ w0 2))))
                 (plasma (xe2:render-plasma h0 w0 :graininess graininess))
                 (value nil))
            (dotimes (i h0)
              (dotimes (j w0)
                (setf value (aref plasma i j))
                (when (< cutoff value)
                  (when (or (null distance)
                            (< (distance (+ j r0) (+ c0 i) row column) distance))
                    (percent-of-time density
                      [drop-cell self (clone object) (+ r0 i) (+ c0 j) :no-collisions t]))))))))
      
    (define-method generate cloud (&key (height 100)
                                        (width 100)
                                        (protostars 30)
                                        (sequence-number (genseq)))
      (setf <height> height <width> width)
      [create-default-grid self]
      ;; space dust
      (dotimes (n 100) 
        (let ((dust (clone =dust-particle=)))
          [add-sprite self dust]
          [update-position dust (random 1590) (random 1590)]))
      (dotimes (i width)
        (dotimes (j 8)
          (percent-of-time 5
            [drop-cell self (clone =shocker=) j i])))
      ;; (dotimes (n 3)
      ;;   (let ((drone (clone =drone=)))
      ;;     [add-sprite self drone]
      ;;     [update-position drone (+ 20 (random 1500)) (+ 20 (random 400))]))
      [drop-cell self (clone =navpoint= :alpha) 8 10]
      [drop-cell self (clone =navpoint= :beta) 88 23]
      [drop-cell self (clone =navpoint= :gamma) 18 90]
      [drop-cell self (clone =launchpad=) 88 60])
(defworld dvo-orbit
  (name :initform "DVO UV Shield Cloud")
  (scale :initform '(50 m))
  (edge-condition :initform :block)
  (background :initform "dvo-orbit")
  (ambient-light :initform :total)
  (description :initform "foo"))
        
(define-method begin-ambient-loop dvo-orbit ()
  (play-music "dvo" :loop t))

(define-method generate dvo-orbit (&key (height 200)
                                        (width 100)
                                        (protostars 30)
                                        (sequence-number (genseq)))
        (setf <height> height <width> width)
        [create-default-grid self]
        (dotimes (n 40)
          [drop-cell self (clone =macrovirus=) (+ 150 (random 20)) (random 100)])
        [drop-cell self (clone =launchpad=) 195 30])

(defmission enter-dvo-orbit (:title "Enter DVO orbit."
                                    :address '(=dvo-orbit=)))
(defworld title-screen
  (edge-condition :initform :block)
  (title-screen :initform t)
  (background :initform "title")
  (ambient-light :initform :total)
  (description :initform "foo"))

(define-method begin-ambient-loop title-screen ()
  (play-music "theme" :loop t))

(define-method generate title-screen (&rest args)
  (let ((g1 (clone =gateway= :destination '=gather-cloud-data=))
        (g2 (clone =gateway= :destination '=enter-dvo-orbit=))
        (g3 (clone =gateway= :destination '=prologue=)))
    [resize-to-background self]
    [drop-cell self g1 30 20]
    [emote g1 "Mission 1.1: Gather cloud data" :timeout nil]
    [drop-cell self g2 35 32]
    [emote g2 "Mission 1.2: Enter DVO orbit" :timeout nil]
    [drop-cell self g3 40 40]
    [emote g3 "Xioceptor home base" :timeout nil]
    [drop-cell self (clone =launchpad=) 18 18]))

(defmission start-game
    (:address '(=title-screen=)))
(defworld xioceptor
  (name :initform "Xiomacs Interceptor")
  (scale :initform '(2 m))
  (edge-condition :initform :block)
  (background :initform "xioceptor")
  (ambient-light :initform :total)
  (height :initform 45) 
  (width :initform 80)
  (description :initform "foo"))

(defmission prologue  
  (:title "Xioceptor test" :address '(=xioceptor=)))
(defparameter *react-shield-time* 30)

(defparameter *vox-warning-clock* 400)

(defparameter *energy-recovery-interval* 200)

(defcell agent 
  (tile :initform "agent-north")
  (firing :initform nil)
  (items :initform nil)
  (tail-length :initform 3)
  (direction :initform :north)
  (last-direction :initform :north :documentation "Last direction actually moved.")
  (dead :initform nil)
  (last-turn-moved :initform 0)
  (team :initform :player)
  (vox-warning-clock :initform 0)
  (call-clock :initform 0)
  (call-interval :initform 7)
  (hit-points :initform (make-stat :base 20 :min 0 :max 20))
  (energy :initform (make-stat :base 80 :min 0 :max 80))
  (oxygen :initform (make-stat :base 80 :min 0 :max 80))
  (movement-cost :initform (make-stat :base 10))
  (speed :initform (make-stat :base 10 :min 0 :max 10))
  (hearing-range :initform 25)
  (stepping :initform t)
  (light-radius :initform 7)
  (react-shield-clock :initform 0)
  (energy-clock :initform *energy-recovery-interval*)
  (categories :initform '(:actor :obstacle :player :target :container :light-source)))

(define-method warn-maybe agent ()
 (unless <dead>
   (clon:with-fields (vox-warning-clock) self
     (if (> 14 [stat-value self :hit-points])
         (progn 
           (setf vox-warning-clock (max 0 (1- vox-warning-clock)))
           (when (zerop vox-warning-clock)
             (setf vox-warning-clock *vox-warning-clock*)
             [emote self "Shield warning!"]
             [play-sample self "vox-shield"]))
         (setf vox-warning-clock 0)))))

(define-method help agent ()
  [emote self (find-resource-object "quickhelp")])

(define-method loadout agent ()
  [set-character *status* self]
  [emote self '((("\\--- YOU ARE HERE." :foreground ".red"))
                (("Use the arrow keys (or numpad) to move."))
                (("Press SHIFT-direction to shoot."))
                (("Press F1 for help.")))
         :timeout 10.0]
  (push (clone =buster-defun=) <items>))

(define-method blab agent ()
  [emote self '((("I've got to drop sensors on all three nav points."))
                (("Nav points look like this: ") (nil :image "navpoint-off"))
                (("I'd better keep moving.")))
         :timeout 10.0])
               
(define-method freak agent ()
  [play-sample self "vox-brennan"]
  [emote self '((("BRENNAN:"))
                (("I'm getting some radiation. Watch your scanners,"))
                (("and focus on reaching those nav points.")))
         :timeout 10.0])
  
(define-method alienate agent ()
  [play-sample self "vox-unidentified"]
  (play-music "neo-eof" :loop t)
  [emote self '((("#<AUDIO-LOG>"))
                (("Warning: unknown data format.")))
                :timeout 10.0])
  
(define-method start agent ())

(define-method expend-energy agent (points)
  (if (>= [stat-value self :energy] points)
      (prog1 t [stat-effect self :energy (- points)])
      (prog1 nil 
        [say self "Insufficient energy."]
        [play-sample self "error"])))

(define-method hit agent (&optional other)
 [damage self 5])

(define-method damage agent (points)
  (if (zerop <react-shield-clock>)
      (labels ((do-circle (image)
                 (prog1 t
                   (multiple-value-bind (x y) 
                       [image-coordinates self]
                     (let ((x0 (+ x 8))
                           (y0 (+ y 8)))
                       (draw-circle x0 y0 25 :destination image)
                       (draw-circle x0 y0 30 :destination image)
                       (draw-circle x0 y0 35 :destination image)
                       (draw-circle x0 y0 40 :destination image))))))
        (setf <react-shield-clock> *react-shield-time*)
        [play-sample self "shield-warning"]
        [>>add-overlay :viewport #'do-circle]
        [parent>>damage self points])
      [play-sample self "ice"]))
  
(define-method pause agent ()
  [pause *world*])

(defparameter *agent-tiles* '(:north "agent-north"
                             :south "agent-south"
                             :east "agent-east"
                             :west "agent-west"))

(define-method aim agent (direction)
  (setf <direction> direction)
  (setf <tile> (getf *agent-tiles* direction)))

(define-method move agent (&optional direction)
  (unless <dead>
    (let ((phase (field-value :phase-number *world*))
          (dir (or direction <direction>)))
      (unless (= <last-turn-moved> phase)
        (setf <last-turn-moved> phase)
        [aim self dir]
        (when [parent>>move self dir]
          (setf <last-direction> dir))))))

(define-method space-at-head agent ()
  (values <row> <column>))

(define-method category-at-head agent (category)
  (multiple-value-bind (row column) 
      [space-at-head self]
    [category-at-p *world* row column category]))

(define-method item-at-head agent ()
  [category-at-head self :item])

(define-method obstacle-at-head agent ()
  [category-at-head self :obstacle])
  
(define-method push agent () 
  (unless <dead>
    (if (= (length <items>) <tail-length>)
        (progn 
          [say self "Maximum capacity reached."]
          [play-sample self "error"])
        (let ((item [item-at-head self]))
          (if item
              (progn (setf <items> (append <items> (list item)))
                     [play-sample self "doorbell"]
                     [print-items self]
                     [delete-from-world item])
              [say self "Nothing to push."])))))
        
(define-method pop agent ()
  (unless (or <dead> [in-overworld self])
    (clon:with-fields (items) self
      (multiple-value-bind (row column)
          [space-at-head self]
        (let ((item (car items)))
          (if (clon:object-p item)
              (progn (setf items (delete item items))
                     [play-sample self "doorbell2"]
                     [drop-cell *world* item row column]
                     [print-items self])
              [say self "Nothing to drop."]))))))
  
(define-method act agent ()
  (unless <dead>
    (let ((gateway [category-at-p *world* <row> <column> :gateway]))
      (if (clon:object-p gateway)
          [activate gateway]
          (cond ([category-at-head self :action]
                 [do-action [category-at-head self :action]])
                ([category-at-head self :item]
                 [push self])
                (t 
                 [play-sample self "error"]
                 [say self "Nothing to do here."]))))))

(define-method expend-item agent ()
  (pop <items>)
  [print-items self])

(define-method rotate agent () 
  (unless <dead>
    (clon:with-fields (items) self
      (if items
          (let ((tail (car (last items)))
                (newlist (butlast items)))
            [play-sample self "doorbell3"]
            (setf items (cons tail newlist))
            [print-items self])
          (progn 
            [play-sample self "error"]
            [say self "Cannot rotate empty list."])))))

(define-method call agent (&optional direction)
  (unless <dead>
    (when (zerop <call-clock>)
      (when direction
        [aim self direction])
      (let ((item (car <items>)))
        (if (and item [in-category item :item]
                 (clon:has-method :call item))
            (progn 
              (when [expend-energy self (field-value :energy-cost item)]
                (message "Calling.")
                [call item self]
                (setf <call-clock> (field-value :call-interval item))))
            [say self "Cannot call."])))))

(define-method print-items agent ()
  (labels ((print-item (item)
             [>>print :narrator nil :image (field-value :tile item)]
             [>>print :narrator "  "]
             [>>print :narrator (get-some-object-name item)]
             [>>print :narrator "  "])
           (newline ()
             [>>newline :narrator]))
    (dolist (item <items>)
      (print-item item))
    (newline)))
      
(define-method run agent () 
  ;; (when *mission*
  ;;   (when [is-completed *mission*]
  ;;     [emote self "I win!"]))
;;  [update-tiles self]
  [warn-maybe self]
  (when (plusp <call-clock>)
    (decf <call-clock>))
  (when (plusp <energy-clock>)
    (decf <energy-clock>))
  (when (zerop <energy-clock>)
    (setf <energy-clock> *energy-recovery-interval*)
    [stat-effect self :energy 1])
  (when (plusp <react-shield-clock>)
    (decf <react-shield-clock>)
    [play-sample self "shield-sound"]
    (labels ((do-circle (image)
               (prog1 t
                 (multiple-value-bind (x y) 
                     [image-coordinates self]
                   (let ((x0 (+ x 8))
                         (y0 (+ y 8)))
                     (draw-circle x0 y0 (+ 25 (random 3)) :destination image :color (car (one-of (list ".cyan" ".hot pink" ".white"))))
                     (draw-circle x0 y0 (+ 30 (random 3))  :destination image :color (car (one-of (list ".cyan" ".hot pink" ".white")))))))))
      [>>add-overlay :viewport #'do-circle]))
  (when (or (keyboard-modifier-down-p :lshift)
            (keyboard-modifier-down-p :rshift))
    [call self <direction>])
  (dolist (item <items>)
    (when [in-category item :actor]
      [run item])))

(define-method quit agent ()
  (xe2:quit :shutdown))

(define-method do-exit agent ()
  [exit *universe*])

(define-method die agent ()
      (unless <dead>
    (setf <tile> "agent-disabled")
    (dotimes (n 30)
      [drop self (clone =explosion=)])
    [play-sample self "gameover"]
    [say self "You died. Press escape to reset."]
    (setf <dead> t)))

(define-method restart agent ()
  (let ((agent (clone =agent=)))
    (setf *player* agent)
    [destroy *universe*]
    [set-player *universe* agent]
    (let ((mission (clone =start-game=)))
      [begin mission *player*])
    [loadout agent]))

;;; Player upgrade

(defcell tail-defun 
  (name :initform "Body Extender Segment")
  (tile :initform "tail-defun")
  (call-interval :initform 20)
  (energy-cost :initform 0)
  (categories :initform '(:item :target :defun)))

(define-method call tail-defun (caller)
  [upgrade caller]
  [expend-item caller])
(defgame :void
    (:title "Void Mission"
     :description "A sci-fi roguelike game in Common Lisp."
     :creator "David T. O'Toole <dto@gnu.org>"
     :screen-width *width*
     :screen-height *height*
     :timestep *timestep*
     :physics-function #'void:physics)
    ;; create some objects
    (setf *prompt* (clone =void-prompt=))
    (setf *universe* (clone =universe=))
    (setf *player* (clone =agent=))
    (setf *narrator* (clone =narrator=))
    (setf *status* (clone =status=))
    [set-player *universe* *player*]
    (setf *viewport* (clone =viewport=))
    ;; status
    [resize *status* :height *status-height* :width *width*]
    [move *status* :x 8 :y (- *height* *status-height*)]
    [hide *status*]
    ;; configure the view
    [resize *viewport* :height *height* :width *width*]
    [move *viewport* :x 0 :y 0]
    [set-origin *viewport* :x 0 :y 0 
                :height (truncate (/ *height* *grid-size*))
                :width (truncate (/ *width* *grid-size*))]
    [resize *prompt* :height 20 :width 100]
    [move *prompt* :x 0 :y 0]
    [hide *prompt*]
    [resize *narrator* :height 80 :width *width*]
    [move *narrator* :x 0 :y (- *height* 80)]
    [set-verbosity *narrator* 0]
    [install-keybindings *prompt*]
    (xe2:install-widgets *prompt* *viewport* *status*)
    (xe2:enable-classic-key-repeat 100 60)
    ;; now play!
    (let ((mission (clone =start-game=)))
    ;;(let ((mission (clone =gather-cloud-data=)))
      [configure *universe*
                 :narrator *narrator*
                 :prompt *prompt*
                 :viewport *viewport*]
      [begin mission *player*])
    [loadout *player*])
